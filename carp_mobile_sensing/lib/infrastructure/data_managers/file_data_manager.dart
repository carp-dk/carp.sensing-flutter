/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../infrastructure.dart';

/// Creates a [FileDataManager] for data endpoints of type
/// [DataEndPointTypes.FILE].
///
/// Registered in the [DataManagerRegistry] by
/// [SmartPhoneClientManager.configure].
class FileDataManagerFactory implements DataManagerFactory {
  @override
  String get type => DataEndPointTypes.FILE;

  @override
  DataManager create() => FileDataManager();
}

/// A data manager that writes [Measurement]s as JSON to files on the phone.
///
/// Used when the protocol's data endpoint is a [FileDataEndPoint]. Each file
/// holds a JSON array of measurements. When a file grows beyond
/// [FileDataEndPoint.bufferSize] bytes, it is closed, optionally zipped, and a
/// new file is started.
///
/// Key points:
///  * Emits [FileDataManagerEvent]s on [events] when files are created and
///    closed, so e.g. an upload manager can pick up closed files.
///  * Encryption ([FileDataEndPoint.encrypt]) is not implemented yet. Only the
///    [FileDataManagerEventTypes.fileEncrypted] event is emitted.
///  * If a write fails, the file is reset and the write is retried.
///
/// The path and filename format is
///
///   `~/carp/deployments/<study_deployment_id>/data/carp-data-yyyy-mm-dd-hh-mm-ss-ms.json.zip`
///
/// where `~` is the folder where an application can place files that are private
/// to the application (see [Settings.getDataBasePath]).
///
/// On iOS, this is the `NSDocumentsDirectory` and the files can be accessed via
/// the MacOS Finder.
///
/// On Android, Flutter files are stored in the `AppData` directory, which is
/// located in the `data/data/<package_name>/app_flutter` folder.
/// Files can be accessed via AndroidStudio.
class FileDataManager extends AbstractDataManager {
  String? _path;
  String? _filename;
  File? _file;
  IOSink? _sink;
  bool _initialized = false;
  int _flushingSink = 0;

  @override
  String get type => DataEndPointTypes.FILE;

  /// The [dataEndPoint] cast to a [FileDataEndPoint].
  /// Only valid after [configure] has been called.
  FileDataEndPoint get fileDataEndPoint =>
      super.dataEndPoint! as FileDataEndPoint;

  @override
  Future<void> configure({
    required DataEndPoint dataEndPoint,
    required SmartphoneDeployment deployment,
    required Stream<Measurement> measurements,
  }) async {
    assert(dataEndPoint is FileDataEndPoint);
    await super.configure(
      dataEndPoint: dataEndPoint,
      deployment: deployment,
      measurements: measurements,
    );

    await Settings().getDeploymentBasePath(studyDeploymentId);

    if (fileDataEndPoint.encrypt) {
      assert(
        fileDataEndPoint.publicKey != null,
        'A public key is required if files are to be encrypted.',
      );
      assert(
        fileDataEndPoint.publicKey!.isNotEmpty,
        'A non-empty public key is required if files are to be encrypted.',
      );
    }

    // Initializing the local directory and file
    await path;
    await file;
    await sink;

    info('Initializing FileDataManager...');
    info('Data file path : $_path');
    info('Buffer size    : ${fileDataEndPoint.bufferSize.toString()} bytes');
  }

  @override
  Future<void> onMeasurement(Measurement measurement) async =>
      await write(measurement);

  @override
  Future<void> onDone() async => await close();

  /// The full path where data files are stored on the device.
  Future<String> get path async =>
      Settings().getDataBasePath(studyDeploymentId);

  /// Full path and filename of the current file, on the format
  ///
  ///   `~/carp/deployments/<study_deployment_id>/data/carp-data-yyyy-mm-dd-hh-mm-ss-ms.json`
  ///
  /// where the date is the creation time in UTC (zulu time).
  /// A new name is generated each time a file is flushed.
  Future<String> get filename async {
    if (_filename == null) {
      final created = DateTime.now()
          .toUtc()
          .toString()
          .replaceAll(RegExp(r':'), '-')
          .replaceAll(RegExp(r' '), '-')
          .replaceAll(RegExp(r'\.'), '-');

      await path;
      _filename = '$_path/carp-data-$created.json';
    }
    return _filename!;
  }

  /// The current file being written to.
  ///
  /// Created on first access, which also emits a
  /// [FileDataManagerEventTypes.fileCreated] event.
  Future<File> get file async {
    if (_file == null) {
      final newFilename = await filename;
      _file = File(newFilename);
      info("Creating file '$newFilename'");
      addEvent(
        FileDataManagerEvent(
          FileDataManagerEventTypes.fileCreated,
          newFilename,
        ),
      );
    }
    return _file!;
  }

  /// The [IOSink] used to append to the current [file].
  ///
  /// Opened on first access, which also writes the opening `[` of the JSON array.
  Future<IOSink> get sink async {
    if (_sink == null) {
      // open the file's sink for writing in append mode
      _sink = (await file).openWrite(mode: FileMode.append);
      // since this file will contain a list of json objects, write a '['
      _sink!.write('[\n');
      _initialized = true;
    }
    return _sink!;
  }

  /// Writes a JSON encoded [measurement] to the current file.
  ///
  /// If the sink is not ready, the write is retried after 2 seconds.
  /// Calls [flush] when the file size exceeds [FileDataEndPoint.bufferSize].
  Future<void> write(Measurement measurement) async {
    // Check if the sink is ready for writing...
    if (!_initialized) {
      info('File sink not ready -- delaying for 2 sec...');
      return Future.delayed(
        const Duration(seconds: 2),
        () => write(measurement),
      );
    }

    final json = jsonEncode(measurement);

    await sink.then((activeSink) async {
      try {
        // always add a comma directly after json
        activeSink.write('$json\n,\n');
        debug(
          'Writing measurement to file - type: ${measurement.dataType.toString()}',
        );

        await file.then((activeFile) async {
          await activeFile.length().then((len) {
            if (len > fileDataEndPoint.bufferSize) {
              flush(activeFile, activeSink);
            }
          });
        });
      } catch (error) {
        warning('Error writing to file - $error');
        _initialized = false;
        write(measurement);
      }
    });
  }

  /// Closes [flushFile] and its [flushSink], and zips the file if
  /// [FileDataEndPoint.zip] is true.
  ///
  /// Resets the current file, so the next [write] starts a new file.
  /// Emits a [FileDataManagerEventTypes.fileClosed] event with the final path
  /// (ending in `.zip` if zipped). Calls for a sink that is already being
  /// flushed are ignored.
  Future<void> flush(File flushFile, IOSink flushSink) async {
    // fast exit if we're already flushing this file/sink
    if (flushSink.hashCode == _flushingSink) return;

    _flushingSink = flushSink.hashCode;

    // Reset the file (setting it and its name and sink to null),
    // so a new file (and sink) can be created.
    _sink = null;
    _initialized = false;
    _filename = null;
    _file = null;

    final jsonFilePath = flushFile.path;
    var finalFilePath = jsonFilePath;

    info("Written JSON to file '$jsonFilePath'. Closing it.");
    flushSink.write('\n]\n');

    // once finished closing the file, then zip and encrypt it
    flushSink.close().then((value) {
      if (fileDataEndPoint.zip) {
        // create a new zip file and add the JSON file to this zip file
        final encoder = ZipFileEncoder();
        final jsonFile = File(jsonFilePath);
        finalFilePath = '$jsonFilePath.zip';
        encoder.create(finalFilePath);
        encoder.addFile(jsonFile);
        encoder.close();

        // once the file is zipped to a new zip file, delete the old JSON file
        jsonFile.delete();
      }

      // encrypt the zip file
      if (fileDataEndPoint.encrypt) {
        //TODO : implement encryption
        // if the encrypted file gets another name, remember to
        // update _jsonFilePath
        addEvent(
          FileDataManagerEvent(
            FileDataManagerEventTypes.fileEncrypted,
            finalFilePath,
          ),
        );
      }

      addEvent(
        FileDataManagerEvent(
          FileDataManagerEventTypes.fileClosed,
          finalFilePath,
        ),
      );
    });
  }

  @override
  Future<void> close() async {
    _initialized = false;
    await file.then((activeFile) async {
      sink.then((activeSink) async {
        await flush(activeFile, activeSink);
        await _sink?.close();
        await super.close();
      });
    });
  }
}

/// A status event from a [FileDataManager], carrying the path of the file
/// it concerns.
///
/// See [FileDataManagerEventTypes] for the possible event types.
class FileDataManagerEvent extends DataManagerEvent {
  /// The full path and filename for the file.
  String path;

  /// Create a new [FileDataManagerEvent].
  FileDataManagerEvent(super.type, this.path);

  @override
  String toString() => 'FileDataManagerEvent - type: $type, path: $path';
}

/// The event types used in [FileDataManagerEvent], in addition to those in
/// [DataManagerEventTypes].
class FileDataManagerEventTypes extends DataManagerEventTypes {
  /// A new data file was created and is being written to.
  static const String fileCreated = 'file_created';

  /// A data file was closed (and zipped, if enabled) and is ready for upload.
  static const String fileClosed = 'file_closed';

  /// A data file was deleted. Not emitted by [FileDataManager] itself, but
  /// used by managers that delete files after upload.
  static const String fileDeleted = 'file_deleted';

  /// A data file was encrypted. Encryption is not implemented yet, so this
  /// event only signals that [FileDataEndPoint.encrypt] was set.
  static const String fileEncrypted = 'file_encrypted';
}

/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../infrastructure.dart';

class FileDataManagerFactory implements DataManagerFactory {
  @override
  String get type => DataEndPointTypes.FILE;

  @override
  DataManager create() => FileDataManager();
}

/// Stores [Measurement] objects on the device's local storage media.
/// Supports compression (zip) and encryption.
///
/// The path and filename format is
///
///   `~/carp/deployments/<study_deployment_id>/data/carp-data-yyyy-mm-dd-hh-mm-ss-ms.json.zip`
///
/// where `~` is the folder where an application can place files that are private
/// to the application.
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

    // _fileDataEndPoint = dataEndPoint as FileDataEndPoint;
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

    // Initializing the the local directory and file
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

  /// Full path and filename according to this format:
  ///
  ///   `~/carp/deployments/<study_deployment_id>/data/carp-data-yyyy-mm-dd-hh-mm-ss-ms.json`
  ///
  /// where the date is in UTC format / zulu time.
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

  /// The currently used [IOSink].
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

  /// Writes a JSON encoded [measurement] to the file.
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

  /// Flushes data to the file, compress, encrypt, and close it.
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

/// A status event for this file data manager.
/// See [FileDataManagerEventTypes] for a list of possible event types.
class FileDataManagerEvent extends DataManagerEvent {
  /// The full path and filename for the file.
  String path;

  /// Create a new [FileDataManagerEvent].
  FileDataManagerEvent(super.type, this.path);

  @override
  String toString() => 'FileDataManagerEvent - type: $type, path: $path';
}

/// An enumeration of file data manager event types
class FileDataManagerEventTypes extends DataManagerEventTypes {
  static const String fileCreated = 'file_created';
  static const String fileClosed = 'file_closed';
  static const String fileDeleted = 'file_deleted';
  static const String fileEncrypted = 'file_encrypted';
}

part of 'media.dart';

/// Records audio from the microphone to a file.
///
/// Used for the [MediaSamplingPackage.AUDIO] measure. Recording starts on
/// [onResume] and stops on [onPause]. On stop, the probe adds an [AudioMedia]
/// measurement to the [measurements] stream.
///
/// Key points:
///  * Only one recording can run at a time.
///  * Records raw sound, including any human speech nearby, and produces a lot
///    of data. Use with caution.
///  * The sound file is stored as AAC in an `.mp4` file in the
///    [MediaSamplingPackage.MEDIA_FILES_PATH] folder, named by the [MediaData.id].
///  * The [AudioMedia] data holds the metadata and file name. How the file is
///    uploaded is up to the [DataManager] used in the deployment.
class AudioProbe extends Probe {
  final _recorder = FlutterSoundRecorder();
  String? _path;
  bool _isRecording = false;
  MediaData? _data;
  String? _soundFileName;

  /// Whether a recording is in progress.
  bool get isRecording => _isRecording;

  @override
  bool onInitialize() {
    _recorder.openRecorder();
    return super.onInitialize();
  }

  @override
  Future<bool> onResume() async {
    if (await requestPermissions()) {
      try {
        await _startAudioRecording();
        debug(
          '$runtimeType [$hashCode] - Audio recording started - sound file : $_soundFileName',
        );
      } catch (error) {
        warning('An error occurred trying to start audio recording - $error');
        addError(error);
        return false;
      }
      return true;
    } else {
      return false;
    }
  }

  @override
  Future<bool> onPause() async {
    if (_isRecording) {
      try {
        await _stopAudioRecording();
        debug(' $runtimeType [$hashCode] - Audio recording stopped.');

        // when stopping the audio sampling, stop recording and collect the measurement
        if (_data != null) {
          _data?.endRecordingTime = DateTime.now().toUtc();
          var measurement = Measurement(
            sensorStartTime: _data!.startRecordingTime!.microsecondsSinceEpoch,
            sensorEndTime: _data!.endRecordingTime?.microsecondsSinceEpoch,
            data: _data!,
          );
          addMeasurement(measurement);
        }
      } catch (error) {
        warning('An error occurred trying to stop audio recording - $error');
        addError(error);
      }
    }
    return true;
  }

  @override
  Future<void> onDispose() async {
    await _recorder.closeRecorder();
  }

  Future<void> _startAudioRecording() async {
    // fast out if recording is already in progress (can only record one at a time)
    if (_isRecording) {
      warning(
        'Trying to start audio recording, but recording is already running. '
        'Make sure to stop this audio probe before resuming it.',
      );
      return;
    }

    _data = AudioMedia(
      filename: 'no_file_available',
      startRecordingTime: DateTime.now().toUtc(),
    );
    _soundFileName = await _filePath;
    _data!.path = _soundFileName;
    _data!.filename = _soundFileName!.split("/").last;
    _isRecording = true;

    // start the recording
    await _recorder.startRecorder(toFile: _soundFileName, codec: Codec.aacMP4);
  }

  Future<void> _stopAudioRecording() async {
    _data?.endRecordingTime = DateTime.now().toUtc();

    // stop the recording and close the recorder
    await _recorder.stopRecorder();
    _isRecording = false;
  }

  /// The local path on the device where sound files are stored.
  /// Creates the sound directory, if not existing.
  Future<String> get _mediaPath async {
    if (_path == null) {
      // create a sub-directory for media (audio) files
      final directory = await Directory(
        '${await Settings().getDataBasePath(deployment!.studyDeploymentId)}/${MediaSamplingPackage.MEDIA_FILES_PATH}',
      ).create(recursive: true);

      _path = directory.path;
    }
    return _path!;
  }

  /// The filename of the sound file.
  /// The file is named by the unique id (uuid) of the [MediaData]
  String get _filename => '${_data!.id}.mp4';

  /// The full file path to the sound file.
  Future<String> get _filePath async => "${await _mediaPath}/$_filename";
}

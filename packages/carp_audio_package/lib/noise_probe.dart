part of 'media.dart';

/// A probe collecting noise sampling from the microphone.
///
/// See [PeriodicSamplingConfiguration] on how to configure this probe,
/// including setting the frequency and duration of the sampling rate.
///
/// Does not record sound. Instead reports the audio level with a specified
/// frequency, in a given sampling window as a [Noise] data object.
class NoiseProbe extends BufferingPeriodicStreamProbe {
  final NoiseMeter _noiseMeter = NoiseMeter();
  final List<NoiseReading> _noiseReadings = [];
  DateTime? _startRecordingTime, _endRecordingTime;

  @override
  Stream<NoiseReading> get bufferingStream => _noiseMeter.noise;

  // @override
  // Future<bool> onStart() async {
  //   // check permission to access the microphone

  //   // Ask for permission before starting probe.
  //   // Only relevant for Android - on iOS permission is automatically requested.
  //   var status = Platform.isAndroid
  //       ? await Permission.microphone.request()
  //       : PermissionStatus.granted;

  //   return (status == PermissionStatus.granted)
  //       ? super.onStart()
  //       : Future.value(false);

  //   // final status = await Permission.microphone.status;
  //   // if (!status.isGranted) {
  //   //   warning(
  //   //       '$runtimeType - Permission not granted to use to microphone: $status - trying to request it');
  //   //   await Permission.microphone.request();
  //   // }
  //   // return super.onStart();
  // }

  @override
  void onSamplingStart() {
    _startRecordingTime = DateTime.now();
    _noiseReadings.clear();
  }

  @override
  void onSamplingEnd() => _endRecordingTime = DateTime.now();

  @override
  void onSamplingData(dynamic event) {
    if (event is NoiseReading) _noiseReadings.add(event);
  }

  @override
  Future<Measurement?> getMeasurement() async {
    if (_noiseReadings.isNotEmpty) {
      List<num> meanList = [];
      List<num> maxList = [];

      for (var reading in _noiseReadings) {
        meanList.add(reading.meanDecibel);
        maxList.add(reading.maxDecibel);
      }

      Stats meanStats = Stats.fromData(meanList);
      Stats maxStats = Stats.fromData(maxList);
      // get statistics from the list of mean db's
      num mean = meanStats.mean;
      num std = meanStats.sampleValues.standardDeviation;
      num min = meanStats.min;
      // get the max db from the list of max db's
      num max = maxStats.max;

      if (mean.isFinite && std.isFinite && min.isFinite && max.isFinite) {
        return Measurement(
          sensorStartTime:
              _startRecordingTime?.microsecondsSinceEpoch ??
              DateTime.now().microsecondsSinceEpoch,
          sensorEndTime: _endRecordingTime?.microsecondsSinceEpoch,
          data: Noise(
            meanDecibel: mean.toDouble(),
            stdDecibel: std.toDouble(),
            minDecibel: min.toDouble(),
            maxDecibel: max.toDouble(),
          ),
        );
      }
    }

    return null;
  }
}

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

  @override
  void onSamplingStart() {
    _startRecordingTime = DateTime.now();
    _noiseReadings.clear();
  }

  @override
  void onSamplingEnd() => _endRecordingTime = DateTime.now();

  @override
  void onSamplingData(dynamic event) =>
      event is NoiseReading ? _noiseReadings.add(event) : null;

  @override
  Future<Measurement?> getMeasurement() async {
    if (_noiseReadings.isNotEmpty) {
      Stats meanStats = Stats.fromData(
        _noiseReadings
            .map((reading) => reading.meanDecibel)
            .where((e) => e.isFinite),
      );
      Stats maxStats = Stats.fromData(
        _noiseReadings
            .map((reading) => reading.maxDecibel)
            .where((e) => e.isFinite),
      );

      num mean = meanStats.mean;
      num std = meanStats.sampleValues.standardDeviation;
      num min = meanStats.min;
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

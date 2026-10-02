part of 'media.dart';

/// Samples the noise level from the microphone and reports it as [Noise] data.
///
/// Used for the [MediaSamplingPackage.NOISE] measure. Does not record sound.
/// It listens for the duration of each sampling window and reports the mean,
/// standard deviation, min and max decibel of that window. Configure the
/// interval and window duration with a [PeriodicSamplingConfiguration].
///
/// No measurement is added if no finite readings were collected in a window.
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

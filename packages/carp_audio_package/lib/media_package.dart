part of 'media.dart';

/// A sampling package for capturing audio (incl. noise) and video (incl. images).
///
/// To use this package, register it in the [carp_mobile_sensing] package using
///
/// ```
///   SamplingPackageRegistry.register(MediaSamplingPackage());
/// ```
class MediaSamplingPackage extends SmartphoneSamplingPackage {
  /// The name of the folder used for storing audio files.
  static const String MEDIA_FILES_PATH = 'media';

  static const String VIDEO = "${NameSpace.CARP}.video";
  static const String IMAGE = "${NameSpace.CARP}.image";

  /// Measure type for one-time collection of audio from the phone's microphone.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] connected device for data collection.
  ///  * No sampling configuration needed.
  static const String AUDIO = "${NameSpace.CARP}.audio";

  /// Measure type for periodic collection of noise data from the phone's microphone.
  ///  * Event-based (Periodic) measure.
  ///  * Uses the [Smartphone] master device for data collection.
  ///  * Use a [PeriodicSamplingConfiguration] for configuration.
  static const String NOISE = "${NameSpace.CARP}.noise";

  @override
  DataTypeSamplingSchemeMap
  get samplingSchemes => DataTypeSamplingSchemeMap.from([
    DataTypeSamplingScheme(
      CamsDataTypeMetaData(
        type: AUDIO,
        displayName: "Audio Recording",
        timeType: DataTimeType.TIME_SPAN,
        dataEventType: DataEventType.ONE_TIME,
        permissions: [Permission.microphone],
      ),
    ),
    DataTypeSamplingScheme(
      CamsDataTypeMetaData(
        type: VIDEO,
        displayName: "Video Recording",
        timeType: DataTimeType.TIME_SPAN,
        dataEventType: DataEventType.ONE_TIME,
        // don't automatically request permission for camera - should be done in the app
        // permissions: [Permission.camera],
      ),
    ),
    DataTypeSamplingScheme(
      CamsDataTypeMetaData(
        type: IMAGE,
        displayName: "Image Capture",
        timeType: DataTimeType.POINT,
        dataEventType: DataEventType.ONE_TIME,
        // don't automatically request permission for camera - should be done in the app
        // permissions: [Permission.camera],
      ),
    ),
    DataTypeSamplingScheme(
      CamsDataTypeMetaData(
        type: NOISE,
        displayName: "Noise Recording",
        timeType: DataTimeType.TIME_SPAN,
        dataEventType: DataEventType.EVENT,
        permissions: [Permission.microphone],
      ),
      PeriodicSamplingConfiguration(
        interval: const Duration(minutes: 5),
        duration: const Duration(seconds: 10),
      ),
    ),
  ]);

  @override
  Probe? create(String type) => switch (type) {
    AUDIO => AudioProbe(),
    VIDEO => VideoProbe(),
    IMAGE => VideoProbe(),
    NOISE => NoiseProbe(),
    _ => null,
  };

  @override
  void onRegister() {
    FromJsonFactory().registerAll([
      AudioMedia(filename: ''),
      ImageMedia(filename: ''),
      VideoMedia(filename: ''),
      Noise(meanDecibel: 0, stdDecibel: 0, minDecibel: 0, maxDecibel: 0),
    ]);
  }
}

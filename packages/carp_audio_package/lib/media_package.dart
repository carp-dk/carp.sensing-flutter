part of 'media.dart';

/// The sampling package for capturing audio (incl. noise) and video (incl. images).
///
/// Register it before you deploy a protocol that uses its measure types:
///
/// ```dart
/// SamplingPackageRegistry().register(MediaSamplingPackage());
/// ```
///
/// Key points:
///  * [AUDIO] and [NOISE] use the microphone and request the microphone
///    permission.
///  * [VIDEO] and [IMAGE] do not collect anything themselves. The app records
///    the media and must request the camera permission itself (see [VideoProbe]).
///  * Media files are stored in the [MEDIA_FILES_PATH] folder of the
///    deployment's data folder.
///
/// See also [AudioProbe] and [NoiseProbe].
class MediaSamplingPackage extends SmartphoneSamplingPackage {
  /// The name of the folder used for storing media files.
  static const String MEDIA_FILES_PATH = 'media';

  /// Measure type for a video recorded by the app ([VideoMedia]).
  ///  * One-time measure.
  ///  * Uses the [Smartphone] primary device.
  ///  * The app creates the measurement; [VideoProbe] only acts as a placeholder.
  static const String VIDEO = "${NameSpace.CARP}.video";

  /// Measure type for an image captured by the app ([ImageMedia]).
  ///  * One-time measure.
  ///  * Uses the [Smartphone] primary device.
  ///  * The app creates the measurement; [VideoProbe] only acts as a placeholder.
  static const String IMAGE = "${NameSpace.CARP}.image";

  /// Measure type for one-time collection of audio from the phone's microphone.
  ///  * One-time measure.
  ///  * Uses the [Smartphone] primary device for data collection.
  ///  * No sampling configuration needed.
  ///  * Collected as [AudioMedia] data.
  static const String AUDIO = "${NameSpace.CARP}.audio";

  /// Measure type for periodic collection of noise data from the phone's microphone.
  ///  * Event-based (Periodic) measure.
  ///  * Uses the [Smartphone] primary device for data collection.
  ///  * Use a [PeriodicSamplingConfiguration] for configuration. Default is
  ///    10 seconds every 5 minutes.
  ///  * Collected as [Noise] data.
  static const String NOISE = "${NameSpace.CARP}.noise";

  @override
  DataTypeSamplingSchemeMap get samplingSchemes => DataTypeSamplingSchemeMap.from([
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
      PeriodicSamplingConfiguration(interval: const Duration(minutes: 5), duration: const Duration(seconds: 10)),
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

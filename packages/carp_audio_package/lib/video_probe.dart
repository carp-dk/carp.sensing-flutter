part of 'media.dart';

/// A no-op probe for the video or image measure.
///
/// This probes check permissions to access the camera, but does not collect
/// the image/video itself. It merely is a placeholder
/// for being able to add a video/image measure to a protocol.
class VideoProbe extends MeasurementProbe {
  @override
  Future<Measurement?> getMeasurement() async => null; // the measurement is created in the app from the VideoUserTask
}

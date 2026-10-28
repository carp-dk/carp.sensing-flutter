part of 'media.dart';

/// A placeholder probe for the video and image measures.
///
/// Lets you add [MediaSamplingPackage.VIDEO] and [MediaSamplingPackage.IMAGE]
/// measures to a protocol. It collects nothing: the app captures the media and
/// creates the [VideoMedia] or [ImageMedia] measurement itself, typically
/// from a user task.
class VideoProbe extends MeasurementProbe {
  @override
  Future<Measurement?> getMeasurement() async => null; // the measurement is created in the app from the VideoUserTask
}

part of 'media.dart';

/// A [ServiceConfiguration] for the phone's microphone.
///
/// Add it to a protocol - `addConnectedDevice(MicrophoneService(), phone)` -
/// to record audio or noise. The microphone is a permission of its own, so it
/// is a service of its own: a study that does not deploy it can never ask for it.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class MicrophoneService extends ServiceConfiguration<ServiceRegistration> {
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.MicrophoneService';
  static const String DEFAULT_ROLE_NAME = 'Microphone Service';

  MicrophoneService({String? roleName})
    : super(roleName: roleName ?? DEFAULT_ROLE_NAME);

  @override
  Function get fromJsonFunction => _$MicrophoneServiceFromJson;
  factory MicrophoneService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<MicrophoneService>(json);
  @override
  Map<String, dynamic> toJson() => _$MicrophoneServiceToJson(this);
}

/// A [ServiceConfiguration] for the phone's camera.
///
/// Add it to a protocol - `addConnectedDevice(CameraService(), phone)` - to
/// capture images or video.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CameraService extends ServiceConfiguration<ServiceRegistration> {
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.CameraService';
  static const String DEFAULT_ROLE_NAME = 'Camera Service';

  CameraService({String? roleName})
    : super(roleName: roleName ?? DEFAULT_ROLE_NAME);

  @override
  Function get fromJsonFunction => _$CameraServiceFromJson;
  factory CameraService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<CameraService>(json);
  @override
  Map<String, dynamic> toJson() => _$CameraServiceToJson(this);
}

/// A [DeviceManager] for a media capture service on the phone.
abstract class MediaServiceManager<TConfiguration extends ServiceConfiguration>
    extends ServiceManager<TConfiguration, ServiceRegistration> {
  MediaServiceManager(super.deviceType, {super.configuration});

  @override
  ServiceRegistration createRegistration() =>
      ServiceRegistration(deviceDisplayName: displayName);

  @override
  bool get canConnect => true;

  @override
  void onConfigure() {}

  @override
  Future<DeviceStatus> onConnect() async => DeviceStatus.connected;

  @override
  Future<bool> onDisconnect() async => true;
}

/// A [DeviceManager] for the phone's microphone.
class MicrophoneServiceManager extends MediaServiceManager<MicrophoneService> {
  MicrophoneServiceManager([MicrophoneService? configuration])
    : super(MicrophoneService.DEVICE_TYPE, configuration: configuration);

  @override
  String? get displayName => 'Microphone';

  @override
  List<Permission> get permissions => [Permission.microphone];
}

/// A [DeviceManager] for the phone's camera.
class CameraServiceManager extends MediaServiceManager<CameraService> {
  CameraServiceManager([CameraService? configuration])
    : super(CameraService.DEVICE_TYPE, configuration: configuration);

  @override
  String? get displayName => 'Camera';

  @override
  List<Permission> get permissions => [Permission.camera];
}

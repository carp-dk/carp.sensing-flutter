part of 'communication.dart';

/// A [ServiceConfiguration] for the phone's call log.
///
/// Add it to a protocol - `addConnectedDevice(PhoneLogService(), phone)` - to
/// collect the phone log. Call log is a Play Store sensitive permission, so it
/// is a service of its own: a study that does not deploy it can never ask for it.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class PhoneLogService extends ServiceConfiguration<ServiceRegistration> {
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.PhoneLogService';
  static const String DEFAULT_ROLE_NAME = 'Phone Log Service';

  PhoneLogService({String? roleName})
    : super(roleName: roleName ?? DEFAULT_ROLE_NAME);

  @override
  Function get fromJsonFunction => _$PhoneLogServiceFromJson;
  factory PhoneLogService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<PhoneLogService>(json);
  @override
  Map<String, dynamic> toJson() => _$PhoneLogServiceToJson(this);
}

/// A [ServiceConfiguration] for the phone's text messages (SMS).
///
/// Add it to a protocol - `addConnectedDevice(TextMessageService(), phone)` -
/// to collect text messages. SMS is a Play Store sensitive permission, so it is
/// a service of its own.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class TextMessageService extends ServiceConfiguration<ServiceRegistration> {
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.TextMessageService';
  static const String DEFAULT_ROLE_NAME = 'Text Message Service';

  TextMessageService({String? roleName})
    : super(roleName: roleName ?? DEFAULT_ROLE_NAME);

  @override
  Function get fromJsonFunction => _$TextMessageServiceFromJson;
  factory TextMessageService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<TextMessageService>(json);
  @override
  Map<String, dynamic> toJson() => _$TextMessageServiceToJson(this);
}

/// A [ServiceConfiguration] for the phone's calendar.
///
/// Add it to a protocol - `addConnectedDevice(CalendarService(), phone)` - to
/// collect calendar entries.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class CalendarService extends ServiceConfiguration<ServiceRegistration> {
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.CalendarService';
  static const String DEFAULT_ROLE_NAME = 'Calendar Service';

  CalendarService({String? roleName})
    : super(roleName: roleName ?? DEFAULT_ROLE_NAME);

  @override
  Function get fromJsonFunction => _$CalendarServiceFromJson;
  factory CalendarService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<CalendarService>(json);
  @override
  Map<String, dynamic> toJson() => _$CalendarServiceToJson(this);
}

/// A [DeviceManager] for a communication service on the phone.
abstract class CommunicationServiceManager<
  TConfiguration extends ServiceConfiguration
>
    extends ServiceManager<TConfiguration, ServiceRegistration> {
  CommunicationServiceManager(super.deviceType, {super.configuration});

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

/// A [DeviceManager] for the phone's call log.
class PhoneLogServiceManager
    extends CommunicationServiceManager<PhoneLogService> {
  PhoneLogServiceManager([PhoneLogService? configuration])
    : super(PhoneLogService.DEVICE_TYPE, configuration: configuration);

  @override
  String? get displayName => 'Phone Log';

  @override
  List<Permission> get permissions => [Permission.phone];
}

/// A [DeviceManager] for the phone's text messages.
class TextMessageServiceManager
    extends CommunicationServiceManager<TextMessageService> {
  TextMessageServiceManager([TextMessageService? configuration])
    : super(TextMessageService.DEVICE_TYPE, configuration: configuration);

  @override
  String? get displayName => 'Text Messages';

  @override
  List<Permission> get permissions => [Permission.sms];
}

/// A [DeviceManager] for the phone's calendar.
class CalendarServiceManager
    extends CommunicationServiceManager<CalendarService> {
  CalendarServiceManager([CalendarService? configuration])
    : super(CalendarService.DEVICE_TYPE, configuration: configuration);

  @override
  String? get displayName => 'Calendar';

  @override
  List<Permission> get permissions => [Permission.calendarFullAccess];
}

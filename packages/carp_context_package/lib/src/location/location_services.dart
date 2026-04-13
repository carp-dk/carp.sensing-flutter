part of '../../carp_context_package.dart';

/// An [OnlineService] for the location manager.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class LocationService extends ServiceConfiguration<ServiceRegistration> {
  /// The type of a location service.
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.LocationService';

  /// The default role name for a location service.
  static const String DEFAULT_ROLE_NAME = 'Location Service';

  /// Defines the desired accuracy that should be used to determine the location
  /// data. Default value is [GeolocationAccuracy.balanced].
  GeolocationAccuracy accuracy;

  /// The minimum distance in meters a device must move horizontally
  /// before an update event is generated.
  /// Specify 0 when you want to be notified of all movements.
  double distance = 10;

  /// The time interval between location updates.
  Duration interval = const Duration(minutes: 1);

  /// The title of the notification to be shown to the user when
  /// location tracking takes place in the background.
  /// Only used on Android.
  String? notificationTitle;

  /// The message in the notification to be shown to the user when
  /// location tracking takes place in the background.
  /// Only used on Android.
  String? notificationMessage;

  /// The longer description in the notification to be shown to the user when
  /// location tracking takes place in the background.
  /// Only used on Android.
  String? notificationDescription;

  /// The icon in `Android/app/main/res/drawable` folder.
  /// Only used on Android.
  String? notificationIconName;

  /// Should the app be brought to the front on tap?
  /// Default is false.
  bool notificationOnTapBringToFront;

  /// Create and configure a [LocationService].
  ///
  /// Default configuration is:
  ///  * roleName = "Location Service"
  ///  * accuracy = balanced
  ///  * distance = 10 meters
  ///  * interval = 1 minute
  ///  * notificationOnTapBringToFront = false
  LocationService({
    String? roleName,
    this.accuracy = GeolocationAccuracy.balanced,
    this.distance = 10,
    this.interval = const Duration(minutes: 1),
    this.notificationTitle,
    this.notificationMessage,
    this.notificationDescription,
    this.notificationIconName,
    this.notificationOnTapBringToFront = false,
  }) : super(roleName: roleName ?? DEFAULT_ROLE_NAME);

  @override
  Function get fromJsonFunction => _$LocationServiceFromJson;
  factory LocationService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<LocationService>(json);
  @override
  Map<String, dynamic> toJson() => _$LocationServiceToJson(this);
}

/// A [DeviceManager] for the location service.
class LocationServiceManager extends ContextServiceManager<LocationService> {
  /// A handle to the [LocationManager] used by this service.
  LocationManager manager = LocationManager();

  @override
  String? get displayName => manager.toString();

  LocationServiceManager([LocationService? configuration])
    : super(LocationService.DEVICE_TYPE, configuration: configuration);

  @override
  void onConfigure() => manager.configure(configuration!);

  @override
  Future<DeviceStatus> onConnect() async => manager.enabled
      ? DeviceStatus.connected
      : (await manager.enable().then((_) => DeviceStatus.connected));

  @override
  Future<bool> onHasPermissions() async => await manager.hasPermission();

  @override
  Future<void> onRequestPermissions() async =>
      await manager.requestPermission();
}

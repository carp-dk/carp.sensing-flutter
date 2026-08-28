part of '../connectivity.dart';

/// A [ServiceConfiguration] for scanning nearby Bluetooth devices and beacons.
///
/// Add it to a protocol - `addConnectedDevice(BluetoothScanService(), phone)` -
/// to collect Bluetooth or beacon data. Scanning is a permission of its own, so
/// it is a service of its own: a study that does not deploy it can never ask
/// for it.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class BluetoothScanService extends ServiceConfiguration<ServiceRegistration> {
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.BluetoothScanService';
  static const String DEFAULT_ROLE_NAME = 'Bluetooth Scan Service';

  BluetoothScanService({String? roleName})
    : super(roleName: roleName ?? DEFAULT_ROLE_NAME);

  @override
  Function get fromJsonFunction => _$BluetoothScanServiceFromJson;
  factory BluetoothScanService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<BluetoothScanService>(json);
  @override
  Map<String, dynamic> toJson() => _$BluetoothScanServiceToJson(this);
}

/// A [DeviceManager] for scanning nearby Bluetooth devices and beacons.
class BluetoothScanServiceManager
    extends ServiceManager<BluetoothScanService, ServiceRegistration> {
  BluetoothScanServiceManager([BluetoothScanService? configuration])
    : super(BluetoothScanService.DEVICE_TYPE, configuration: configuration);

  @override
  String? get displayName => 'Bluetooth Scan';

  /// Beacon ranging in the background needs location - scanning alone does not,
  /// but Android only reports beacons when location is available too.
  @override
  List<Permission> get permissions => Platform.isAndroid
      ? [Permission.bluetoothScan, Permission.locationAlways]
      : [Permission.bluetooth];

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

/// The sampling package for scanning nearby Bluetooth devices and beacons.
class BluetoothScanSamplingPackage extends SmartphoneSamplingPackage {
  final _deviceManager = BluetoothScanServiceManager();

  @override
  String get deviceType => BluetoothScanService.DEVICE_TYPE;

  @override
  DeviceManager get deviceManager => _deviceManager;

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: ConnectivitySamplingPackage.BLUETOOTH,
            displayName: "Bluetooth Scan of Nearby Devices",
            timeType: DataTimeType.TIME_SPAN,
          ),
          PeriodicSamplingConfiguration(
            interval: const Duration(minutes: 10),
            duration: const Duration(seconds: 10),
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: ConnectivitySamplingPackage.BEACON,
            displayName: "Ranging iBeacons",
            timeType: DataTimeType.POINT,
          ),
          BeaconRangingPeriodicSamplingConfiguration(),
        ),
      ]);

  @override
  Probe? create(String type) => switch (type) {
    ConnectivitySamplingPackage.BLUETOOTH => BluetoothProbe(),
    ConnectivitySamplingPackage.BEACON => BeaconProbe(),
    _ => null,
  };
}

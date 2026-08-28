/*
 * Copyright 2026 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of '../../../sampling_packages.dart';

/// A [ServiceConfiguration] for the phone's activity recognition service.
///
/// Add it to a protocol - `addConnectedDevice(ActivityService(), phone)` - to
/// collect step events. Activity recognition is a permission of its own, so it
/// is a service of its own: a study that does not deploy it can never ask for it.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class ActivityService extends ServiceConfiguration<ServiceRegistration> {
  static const String DEVICE_TYPE =
      '${CamsDevice.CAMS_DEVICE_NAMESPACE}.ActivityService';
  static const String DEFAULT_ROLE_NAME = 'Activity Service';

  ActivityService({String? roleName})
    : super(roleName: roleName ?? DEFAULT_ROLE_NAME);

  @override
  Function get fromJsonFunction => _$ActivityServiceFromJson;
  factory ActivityService.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<ActivityService>(json);
  @override
  Map<String, dynamic> toJson() => _$ActivityServiceToJson(this);
}

/// A [DeviceManager] for the phone's activity recognition service.
///
/// A singleton - the activity service is one service, even though several
/// sampling packages collect from it (step events here, activity recognition
/// in the context package).
class ActivityServiceManager
    extends ServiceManager<ActivityService, ServiceRegistration> {
  static final ActivityServiceManager _instance = ActivityServiceManager._();
  factory ActivityServiceManager() => _instance;
  ActivityServiceManager._() : super(ActivityService.DEVICE_TYPE);

  @override
  String? get displayName => 'Activity Recognition';

  @override
  List<Permission> get permissions => [Permission.activityRecognition];

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

/// A sampling package for collecting step events from the phone's pedometer.
///
/// Registered by [SensorSamplingPackage] - its data types run on the
/// [ActivityService], not on the phone itself.
class ActivitySamplingPackage extends SmartphoneSamplingPackage {
  final _deviceManager = ActivityServiceManager();

  @override
  String get deviceType => ActivityService.DEVICE_TYPE;

  @override
  DeviceManager get deviceManager => _deviceManager;

  @override
  DataTypeSamplingSchemeMap get samplingSchemes =>
      DataTypeSamplingSchemeMap.from([
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: SensorSamplingPackage.STEP_EVENT,
            displayName: "Step Events",
            timeType: DataTimeType.POINT,
          ),
        ),
        DataTypeSamplingScheme(
          CamsDataTypeMetaData(
            type: SensorSamplingPackage.STEP_COUNT,
            displayName: "Step Count",
            timeType: DataTimeType.POINT,
          ),
        ),
      ]);

  @override
  Probe? create(String type) => switch (type) {
    SensorSamplingPackage.STEP_EVENT => PedometerProbe(),
    SensorSamplingPackage.STEP_COUNT => StepCountProbe(),
    _ => null,
  };

  @override
  void onRegister() => FromJsonFactory().register(ActivityService());
}

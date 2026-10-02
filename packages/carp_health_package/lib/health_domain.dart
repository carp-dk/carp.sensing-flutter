part of 'health_package.dart';

/// Diet, alcohol, smoking, exercise and sleep (DASES) data types.
///
/// Custom health data types that are not part of [HealthDataType]. Their units
/// are listed in [dasesDataTypeToUnit]. The [HealthProbe] does not collect them.
enum DasesHealthDataType {
  /// Number of calories consumed.
  CALORIES_INTAKE,

  /// Units of alcohol.
  ALCOHOL,

  /// Blood alcohol content in percentage.
  BLOOD_ALCOHOL_CONTENT,

  /// Number of smoked cigarettes.
  SMOKED_CIGARETTES,

  /// Number of smoked other thing (pipe, cigar, ...).
  SMOKED_OTHER,

  /// Duration of exercise.
  EXERCISE,

  /// Duration of sleep.
  SLEEP,
}

/// The health platform a [HealthData] point comes from.
///
/// Mapped by index from the `health` plugin's [HealthPlatformType], so the
/// order of the values must match.
enum HealthPlatform { APPLE_HEALTH, GOOGLE_HEALTH_CONNECT }

/// The [HealthDataUnit] of each [DasesHealthDataType].
const Map<DasesHealthDataType, HealthDataUnit> dasesDataTypeToUnit = {
  DasesHealthDataType.CALORIES_INTAKE: HealthDataUnit.KILOCALORIE,
  DasesHealthDataType.ALCOHOL: HealthDataUnit.COUNT,
  DasesHealthDataType.BLOOD_ALCOHOL_CONTENT: HealthDataUnit.PERCENT,
  DasesHealthDataType.SMOKED_CIGARETTES: HealthDataUnit.COUNT,
  DasesHealthDataType.SMOKED_OTHER: HealthDataUnit.COUNT,
  DasesHealthDataType.EXERCISE: HealthDataUnit.NO_UNIT,
  DasesHealthDataType.SLEEP: HealthDataUnit.NO_UNIT,
};

/// The sampling configuration of the [HealthSamplingPackage.HEALTH] measure.
///
/// Sets which [healthDataTypes] to collect. As a [HistoricSamplingConfiguration],
/// each collection fetches data back to the last time data was collected, or
/// [past] back in time on the first collection.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class HealthSamplingConfiguration extends HistoricSamplingConfiguration {
  /// The list of [HealthDataType] to collect.
  ///
  /// Types not supported on the current platform are removed by the
  /// [HealthProbe] when it is initialized.
  List<HealthDataType> healthDataTypes;

  HealthSamplingConfiguration({super.past, required this.healthDataTypes});

  @override
  Function get fromJsonFunction => _$HealthSamplingConfigurationFromJson;

  @override
  Map<String, dynamic> toJson() => _$HealthSamplingConfigurationToJson(this);

  factory HealthSamplingConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<HealthSamplingConfiguration>(json);
}

/// One health data point from Apple Health or Google Health Connect.
///
/// This is the data of every measurement collected by the [HealthProbe]. It is
/// created from the `health` plugin's [HealthDataPoint] using
/// [HealthData.fromHealthDataPoint]. All health data has the same JSON type,
/// `dk.cachet.carp.health` ([HealthSamplingPackage.HEALTH]); the kind of data
/// is given by [healthDataType].
///
/// Key points:
///  * [dateFrom] and [dateTo] are stored in UTC.
///  * [recordId] combines [uuid], [healthDataType] and the time span, because
///    Health Connect gives all samples of one record the same [uuid].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class HealthData extends Data {
  /// A unique UUID of this data point.
  String uuid;

  /// The value of the health data, for example a [NumericHealthValue].
  ///
  /// See [HealthValue].
  // @JsonKey(fromJson: _healthValueFromJson)
  HealthValue value;

  /// Unit of health data.
  ///
  /// Note that the uppercase version is used, e.g. `COUNT` in the case of step counts.
  String unit;

  /// The name of the [HealthDataType] of this data point.
  ///
  /// Note that the uppercase version is used, e.g. `STEPS`.
  String healthDataType;

  /// Start time of this health data, in UTC.
  late DateTime dateFrom;

  /// End time of this health data, in UTC.
  late DateTime dateTo;

  /// The platform this health data point came from.
  HealthPlatform platform;

  /// The id of the device the data point was fetched from.
  String? deviceId;

  /// The id of the source from which the data point was fetched.
  String? sourceId;

  /// The name of the source from which the data point was fetched.
  String? sourceName;

  /// Creates a [HealthData] object. [dateFrom] and [dateTo] are converted to UTC.
  HealthData({
    required this.uuid,
    required this.value,
    required this.unit,
    required this.healthDataType,
    required DateTime dateFrom,
    required DateTime dateTo,
    required this.platform,
    this.deviceId,
    this.sourceId,
    this.sourceName,
  }) : super() {
    this.dateFrom = dateFrom.toUtc();
    this.dateTo = dateTo.toUtc();
  }

  /// Creates a [HealthData] from a `health` plugin [HealthDataPoint].
  factory HealthData.fromHealthDataPoint(HealthDataPoint healthDataPoint) => HealthData(
    uuid: healthDataPoint.uuid,
    value: healthDataPoint.value,
    unit: healthDataPoint.unitString,
    healthDataType: healthDataPoint.typeString,
    dateFrom: healthDataPoint.dateFrom.toUtc(),
    dateTo: healthDataPoint.dateTo.toUtc(),
    platform: HealthPlatform.values[healthDataPoint.sourcePlatform.index],
    deviceId: healthDataPoint.sourceDeviceId,
    sourceId: healthDataPoint.sourceId,
    sourceName: healthDataPoint.sourceName,
  );

  @override
  Function get fromJsonFunction => _$HealthDataFromJson;

  factory HealthData.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<HealthData>(json);

  @override
  Map<String, dynamic> toJson() => _$HealthDataToJson(this);

  @override
  // The uuid is the Health Connect record id, shared by all samples/stages of
  // one record (e.g. heart rate), so add type and time to make it per point.
  String? get recordId =>
      uuid.isEmpty ? null : '$uuid|$healthDataType|${dateFrom.toIso8601String()}|${dateTo.toIso8601String()}';

  /// The JSON type of all health data, `dk.cachet.carp.health`
  /// ([HealthSamplingPackage.HEALTH]), whatever the [healthDataType].
  @override
  String get jsonType => HealthSamplingPackage.HEALTH;

  @override
  String toString() =>
      '${super.toString()}'
      ', healthDataType: $healthDataType'
      ', platform: $platform'
      ', value: $value'
      ', unit: $unit'
      ', dateFrom: $dateFrom'
      ', dateTo: $dateTo';
}

/// A minimal health [Data] type that holds only a [uuid].
///
/// Not produced by the [HealthProbe] and not registered for JSON
/// deserialization in [HealthSamplingPackage.onRegister].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class DummyHealthData extends Data {
  /// A unique UUID of this data point.
  String uuid;
  DummyHealthData({required this.uuid}) : super();

  @override
  Function get fromJsonFunction => _$DummyHealthDataFromJson;

  factory DummyHealthData.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<DummyHealthData>(json);

  @override
  Map<String, dynamic> toJson() => _$DummyHealthDataToJson(this);
}

/// An [AppTask] that asks the user to collect their own health data.
///
/// Add it to the protocol with a trigger, for example a [PeriodicTrigger], on
/// the phone. It shows up in the user's task list, and when the user starts it,
/// it runs as a [HealthUserTask]: it asks for permission to read [types] and
/// then collects them once.
///
/// Key points:
///  * If [measures] has no [HealthSamplingPackage.HEALTH] measure, one is added
///    for [types] using [HealthSamplingPackage.getHealthMeasure].
///  * [type] defaults to [AppTask.HEALTH_ASSESSMENT_TYPE], which the
///    [HealthUserTaskFactory] turns into a [HealthUserTask].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class HealthAppTask extends AppTask {
  /// The health data types to collect.
  ///
  /// Only used to create the health measure when [measures] does not already
  /// contain one.
  List<HealthDataType> types;

  HealthAppTask({
    super.type = AppTask.HEALTH_ASSESSMENT_TYPE,
    super.name,
    super.title,
    super.description,
    super.instructions,
    super.minutesToComplete,
    super.expire,
    super.notification,
    List<Measure>? measures,
    this.types = const [],
  }) {
    measures ??= [];
    // if the list of measures doesn't already contains a health measure for the
    // list of health data types, add it.
    if (measures
            .firstWhere(
              (Measure measure) => measure.type == HealthSamplingPackage.HEALTH,
              orElse: () => Measure(type: 'none'),
            )
            .type !=
        HealthSamplingPackage.HEALTH) {
      measures.add(HealthSamplingPackage.getHealthMeasure(types));
    }
    super.measures = measures;
  }

  @override
  Function get fromJsonFunction => _$HealthAppTaskFromJson;
  factory HealthAppTask.fromJson(Map<String, dynamic> json) => FromJsonFactory().fromJson<HealthAppTask>(json);

  @override
  Map<String, dynamic> toJson() => _$HealthAppTaskToJson(this);
}

part of 'health_package.dart';

/// Diet, Alcohol, Smoking, Exercise, Sleep (DASES) data types.
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

/// Types of health platforms.
enum HealthPlatform { APPLE_HEALTH, GOOGLE_HEALTH_CONNECT }

/// Map a [DasesHealthDataType] to a [HealthDataUnit].
const Map<DasesHealthDataType, HealthDataUnit> dasesDataTypeToUnit = {
  DasesHealthDataType.CALORIES_INTAKE: HealthDataUnit.KILOCALORIE,
  DasesHealthDataType.ALCOHOL: HealthDataUnit.COUNT,
  DasesHealthDataType.BLOOD_ALCOHOL_CONTENT: HealthDataUnit.PERCENT,
  DasesHealthDataType.SMOKED_CIGARETTES: HealthDataUnit.COUNT,
  DasesHealthDataType.SMOKED_OTHER: HealthDataUnit.COUNT,
  DasesHealthDataType.EXERCISE: HealthDataUnit.NO_UNIT,
  DasesHealthDataType.SLEEP: HealthDataUnit.NO_UNIT,
};

/// Specify the configuration on how to collect health data.
///
/// The [healthDataTypes] parameter specifies which [HealthDataType]
/// to collect.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class HealthSamplingConfiguration extends HistoricSamplingConfiguration {
  /// The list of [HealthDataType] to collect.
  List<HealthDataType> healthDataTypes;

  HealthSamplingConfiguration({super.past, required this.healthDataTypes});

  @override
  Function get fromJsonFunction => _$HealthSamplingConfigurationFromJson;

  @override
  Map<String, dynamic> toJson() => _$HealthSamplingConfigurationToJson(this);

  factory HealthSamplingConfiguration.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<HealthSamplingConfiguration>(json);
}

/// A no-op function for deserializing a HealthValue - never used.
HealthValue _healthValueFromJson(json) => NumericHealthValue(numericValue: -1);

/// A [Data] object that holds health data from a [HealthDataPoint].
@JsonSerializable(fieldRename: FieldRename.snake, includeIfNull: false)
class HealthData extends Data {
  /// A unique UUID of this data point.
  String uuid;

  /// The value of the health data.
  ///
  /// See [HealthValue](https://pub.dev/documentation/health/latest/health/HealthValue-class.html)
  @JsonKey(fromJson: _healthValueFromJson)
  HealthValue value;

  /// Unit of health data.
  ///
  /// Note that the uppercase version is used, e.g. `COUNT` in the case of step counts.
  String unit;

  /// Start date-time for this health data.
  late DateTime dateFrom;

  /// End date-time for this health data.
  late DateTime dateTo;

  /// The type of health data -- see [HealthDataType](https://pub.dev/documentation/health/latest/health/HealthDataType.html).
  /// Note that the uppercase version is used, e.g. `STEPS`.
  String healthDataType;

  /// The platform from which this health data point came from
  HealthPlatform platform;

  /// The device id of the phone.
  String deviceId;

  /// The id of the source from which the data point was fetched.
  String sourceId;

  /// The name of the source from which the data point was fetched.
  String sourceName;

  /// Create a [HealthData] object.
  HealthData(
    this.uuid,
    this.value,
    this.unit,
    this.healthDataType,
    DateTime dateFrom,
    DateTime dateTo,
    this.platform,
    this.deviceId,
    this.sourceId,
    this.sourceName,
  ) : super() {
    this.dateFrom = dateFrom.toUtc();
    this.dateTo = dateTo.toUtc();
  }

  /// Create a [HealthData] from a [HealthDataPoint] health data object.
  factory HealthData.fromHealthDataPoint(HealthDataPoint healthDataPoint) =>
      HealthData(
        const Uuid().v1,
        healthDataPoint.value,
        healthDataPoint.unitString,
        healthDataPoint.typeString,
        healthDataPoint.dateFrom.toUtc(),
        healthDataPoint.dateTo.toUtc(),
        HealthPlatform.values[healthDataPoint.sourcePlatform.index],
        healthDataPoint.sourceDeviceId,
        healthDataPoint.sourceId,
        healthDataPoint.sourceName,
      );

  @override
  Function get fromJsonFunction => _$HealthDataFromJson;

  factory HealthData.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<HealthData>(json);

  @override
  Map<String, dynamic> toJson() => _$HealthDataToJson(this);

  /// The json type of this health data is `dk.cachet.carp.health.<healthdatatype>`,
  /// where `<healthdatatype>` is the lowercase version of the [healthDataType].
  @override
  String get jsonType =>
      '${HealthSamplingPackage.HEALTH}.${healthDataType.toLowerCase()}';

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

/// An [AppTask] that can be used  to collect health data.
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class HealthAppTask extends AppTask {
  List<HealthDataType> types;

  HealthAppTask({
    super.type = HealthUserTask.HEALTH_ASSESSMENT_TYPE,
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
  factory HealthAppTask.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<HealthAppTask>(json);

  @override
  Map<String, dynamic> toJson() => _$HealthAppTaskToJson(this);
}

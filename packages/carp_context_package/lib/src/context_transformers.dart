part of '../carp_context_package.dart';

/// A [Data] which can hold an OMH [DataPoint](https://www.openmhealth.org/documentation/#/schema-docs/schema-library/schemas/omh_data-point)
/// and provide its correct OMH [format] and [provenance].
@JsonSerializable(includeIfNull: false, explicitToJson: true)
class OMHContextDataPoint extends Data {
  DataPoint datapoint;

  static String get source =>
      '{smartphone:${DeviceInfoService().deviceID},app:${Settings().appName}}';

  static DataPointAcquisitionProvenance get provenance =>
      DataPointAcquisitionProvenance(
        sourceName: source,
        modality: DataPointModality.SENSED,
      );

  OMHContextDataPoint(this.datapoint);

  @override
  Function get fromJsonFunction => _$OMHContextDataPointFromJson;
  factory OMHContextDataPoint.fromJson(Map<String, dynamic> json) =>
      FromJsonFactory().fromJson<OMHContextDataPoint>(json);
  @override
  Map<String, dynamic> toJson() => _$OMHContextDataPointToJson(this);

  @override
  String get jsonType => "${NameSpace.OMH}.${SchemaSupport.DATA_POINT}";
}

/// Holds an OMH [Geoposition](https://pub.dartlang.org/documentation/openmhealth_schemas/latest/domain_omh_geoposition/Geoposition-class.html)
/// data point.
class OMHGeopositionDataPoint extends OMHContextDataPoint
    implements DataTransformerFactory {
  OMHGeopositionDataPoint(super.datapoint);

  factory OMHGeopositionDataPoint.fromLocationData(Location location) {
    var pos = Geoposition(
      latitude: PlaneAngleUnitValue(
        unit: PlaneAngleUnit.DEGREE_OF_ARC,
        value: location.latitude,
      ),
      longitude: PlaneAngleUnitValue(
        unit: PlaneAngleUnit.DEGREE_OF_ARC,
        value: location.longitude,
      ),
      positioningSystem: PositioningSystem.GPS,
    );

    return OMHGeopositionDataPoint(
      DataPoint(body: pos, provenance: OMHContextDataPoint.provenance),
    );
  }

  factory OMHGeopositionDataPoint.fromJson(Map<String, dynamic> json) =>
      OMHGeopositionDataPoint(DataPoint.fromJson(json));

  static DataTransformer get transformer =>
      ((data) => OMHGeopositionDataPoint.fromLocationData(data as Location));
}

/// Holds an OMH [PhysicalActivity](https://pub.dartlang.org/documentation/openmhealth_schemas/latest/domain_omh_activity/PhysicalActivity-class.html)
/// data point.
class OMHPhysicalActivityDataPoint extends OMHContextDataPoint
    implements DataTransformerFactory {
  OMHPhysicalActivityDataPoint(super.datapoint);

  factory OMHPhysicalActivityDataPoint.fromActivityData(Activity activity) {
    var act = PhysicalActivity(activityName: activity.typeString);

    return OMHPhysicalActivityDataPoint(
      DataPoint(body: act, provenance: OMHContextDataPoint.provenance),
    );
  }

  factory OMHPhysicalActivityDataPoint.fromJson(Map<String, dynamic> json) =>
      OMHPhysicalActivityDataPoint(DataPoint.fromJson(json));

  static DataTransformer get transformer =>
      ((data) =>
          OMHPhysicalActivityDataPoint.fromActivityData(data as Activity));
}

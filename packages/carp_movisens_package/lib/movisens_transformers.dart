/*
 * Copyright 2019 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_movisens_package.dart';

/// A [Data] object that holds an OMH [DataPoint](https://www.openmhealth.org/documentation/#/schema-docs/schema-library/schemas/omh_data-point)
/// made from [MovisensData].
///
/// Base class of the OMH data transformers registered by
/// [MovisensSamplingPackage.onRegister].
// @JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class OMHMovisensDataPoint extends Data {
  /// The OMH data point.
  omh.DataPoint datapoint;

  /// Creates the OMH provenance of [data], naming the phone, the app and the
  /// Movisens sensor as source.
  static omh.DataPointAcquisitionProvenance provenance(MovisensData data) {
    String source =
        '{'
        '"smartphone": "${DeviceInfoService().deviceID}", '
        '"app": "${Settings().appName}", '
        '"sensor_type": "movisens", '
        '"sensor_name": "${data.deviceId}" '
        '}';
    return omh.DataPointAcquisitionProvenance(sourceName: source, modality: omh.DataPointModality.SENSED);
  }

  OMHMovisensDataPoint(this.datapoint);

  @override
  Map<String, dynamic> toJson() => {Serializable.CLASS_IDENTIFIER: dataType}..addAll(datapoint.toJson());
  @override
  String get jsonType => "${NameSpace.OMH}.${omh.SchemaSupport.DATA_POINT}";
}

/// An [OMHMovisensDataPoint] that holds an OMH [HeartRate](https://www.openmhealth.org/documentation/#/schema-docs/schema-library/schemas/omh_heart-rate) data point.
///
/// Its [transformer] converts [MovisensHR] to OMH.
class OMHHeartRateDataPoint extends OMHMovisensDataPoint implements DataTransformerFactory {
  /// The OMH heart rate unit.
  static const String DEFAULT_HR_UNIT = "beats/min";

  OMHHeartRateDataPoint(super.datapoint);

  factory OMHHeartRateDataPoint.fromMovisensHRData(MovisensHR data) {
    var hr = omh.HeartRate(
      heartRate: omh.HeartRateUnitValue(unit: DEFAULT_HR_UNIT, value: data.hr.toDouble()),
    );
    var source =
        '{'
        '"smartphone": "${DeviceInfoService().deviceID}", '
        '"app": "${Settings().appName}", '
        '"sensor_type": "movisens", '
        '"sensor_name": "${data.deviceId}" '
        '}';

    return OMHHeartRateDataPoint(
      omh.DataPoint(
        body: hr,
        provenance: omh.DataPointAcquisitionProvenance(sourceName: source, modality: omh.DataPointModality.SENSED),
      ),
    );
  }

  factory OMHHeartRateDataPoint.fromJson(Map<String, dynamic> json) =>
      OMHHeartRateDataPoint(omh.DataPoint.fromJson(json));

  /// A [DataTransformer] that converts a [MovisensHR] to an
  /// [OMHHeartRateDataPoint].
  static DataTransformer get transformer => ((data) => OMHHeartRateDataPoint.fromMovisensHRData(data as MovisensHR));
}

/// An [OMHMovisensDataPoint] that holds an OMH [StepCount](https://pub.dev/documentation/openmhealth_schemas/latest/domain_omh_activity/StepCount-class.html)
/// data point.
///
/// Its [transformer] converts [MovisensStepCount] to OMH.
class OMHStepCountDataPoint extends OMHMovisensDataPoint implements DataTransformerFactory {
  OMHStepCountDataPoint(super.datapoint);

  factory OMHStepCountDataPoint.fromMovisensStepCountData(MovisensStepCount data) {
    var steps = omh.StepCount(stepCount: data.steps)
      ..effectiveTimeFrame = (omh.TimeFrame()
        ..timeInterval = omh.TimeInterval(startDateTime: data.timestamp, endDateTime: data.timestamp));
    var source =
        '{'
        '"smartphone": "${DeviceInfoService().deviceID}", '
        '"app": "${Settings().appName}", '
        '"sensor_type": "movisens", '
        '"sensor_name": "${data.deviceId}" '
        '}';

    return OMHStepCountDataPoint(
      omh.DataPoint(
        body: steps,
        provenance: omh.DataPointAcquisitionProvenance(sourceName: source, modality: omh.DataPointModality.SENSED),
      ),
    );
  }

  factory OMHStepCountDataPoint.fromJson(Map<String, dynamic> json) =>
      OMHStepCountDataPoint(omh.DataPoint.fromJson(json));

  /// A [DataTransformer] that converts a [MovisensStepCount] to an
  /// [OMHStepCountDataPoint].
  static DataTransformer get transformer =>
      ((data) => OMHStepCountDataPoint.fromMovisensStepCountData(data as MovisensStepCount));
}

/// A [Data] that holds a FHIR [Heart Rate Observation](http://hl7.org/fhir/heartrate.html).
///
/// Its [transformer] converts [MovisensHR] to FHIR.
class FHIRHeartRateObservation extends Data implements DataTransformerFactory {
  /// The heart rate unit. Not used in the FHIR JSON, which uses "beats/minute".
  static const String DEFAULT_HR_UNIT = "beats/min";

  /// The FHIR Observation resource as JSON.
  Map<String, dynamic> fhirJson;

  FHIRHeartRateObservation(this.fhirJson) : super();

  factory FHIRHeartRateObservation.fromMovisensHRData(MovisensHR data) {
    final String fhirString =
        '{'
        '"resourceType": "Observation",'
        '"id": "heart-rate",'
        '"meta": {'
        '  "profile": ['
        '    "http://hl7.org/fhir/StructureDefinition/vitalsigns"'
        '  ]'
        '},'
        '"text": "Heartrate reading from Movisen MoveEcg4",'
        '"status": "final",'
        '"category": ['
        '  {'
        '    "coding": ['
        '      {'
        '        "system": "http://terminology.hl7.org/CodeSystem/observation-category",'
        '        "code": "vital-signs",'
        '        "display": "Vital Signs"'
        '      }'
        '    ],'
        '    "text": "Vital Signs"'
        '  }'
        '],'
        '"code": {'
        '  "coding": ['
        '    {'
        '      "system": "http://loinc.org",'
        '      "code": "8867-4",'
        '      "display": "Heart rate"'
        '    }'
        '  ],'
        '  "text": "Heart rate"'
        '},'
        '"subject": {'
        '  "reference": "Patient/example"'
        '},'
        '"effectiveDateTime": "${data.timestamp}",'
        '"device" : "${data.deviceId}",'
        '"valueQuantity": {'
        '  "value": ${data.hr},'
        '  "unit": "beats/minute",'
        '  "system": "http://unitsofmeasure.org",'
        '  "code": "/min"'
        '}'
        '}';

    return FHIRHeartRateObservation(json.decode(fhirString) as Map<String, dynamic>);
  }

  @override
  Map<String, dynamic> toJson() => {Serializable.CLASS_IDENTIFIER: dataType}..addAll(fhirJson);

  factory FHIRHeartRateObservation.fromJson(Map<String, dynamic> json) => FHIRHeartRateObservation(json);

  @override
  String get jsonType => "${NameSpace.FHIR}.observation-vitalsigns";

  /// A [DataTransformer] that converts a [MovisensHR] to a
  /// [FHIRHeartRateObservation].
  static DataTransformer get transformer => ((data) => FHIRHeartRateObservation.fromMovisensHRData(data as MovisensHR));
}

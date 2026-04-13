/*
 * Copyright 2019 the Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of 'carp_movisens_package.dart';

/// A [Data] object which can hold an OMH [DataPoint](https://www.openmhealth.org/documentation/#/schema-docs/schema-library/schemas/omh_data-point)
/// and provide its correct OMH [format] and [provenance].
// @JsonSerializable(fieldRename: FieldRename.none, includeIfNull: false)
class OMHMovisensDataPoint extends Data {
  omh.DataPoint datapoint;

  static omh.DataPointAcquisitionProvenance provenance(MovisensData data) {
    String source =
        '{'
        '"smartphone": "${DeviceInfoService().deviceID}", '
        '"app": "${Settings().appName}", '
        '"sensor_type": "movisens", '
        '"sensor_name": "${data.deviceId}" '
        '}';
    return omh.DataPointAcquisitionProvenance(
      sourceName: source,
      modality: omh.DataPointModality.SENSED,
    );
  }

  OMHMovisensDataPoint(this.datapoint);

  @override
  Map<String, dynamic> toJson() =>
      {Serializable.CLASS_IDENTIFIER: dataType}..addAll(datapoint.toJson());
  @override
  String get jsonType => "${NameSpace.OMH}.${omh.SchemaSupport.DATA_POINT}";
}

/// A [OMHMovisensDataPoint] that holds an OMH [HeartRate](https://www.openmhealth.org/documentation/#/schema-docs/schema-library/schemas/omh_heart-rate) data point.
class OMHHeartRateDataPoint extends OMHMovisensDataPoint
    implements DataTransformerFactory {
  static const String DEFAULT_HR_UNIT = "beats/min";

  OMHHeartRateDataPoint(super.datapoint);

  factory OMHHeartRateDataPoint.fromMovisensHRData(MovisensHR data) {
    var hr = omh.HeartRate(
      heartRate: omh.HeartRateUnitValue(
        unit: DEFAULT_HR_UNIT,
        value: data.hr.toDouble(),
      ),
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
        provenance: omh.DataPointAcquisitionProvenance(
          sourceName: source,
          modality: omh.DataPointModality.SENSED,
        ),
      ),
    );
  }

  factory OMHHeartRateDataPoint.fromJson(Map<String, dynamic> json) =>
      OMHHeartRateDataPoint(omh.DataPoint.fromJson(json));

  static DataTransformer get transformer =>
      ((data) => OMHHeartRateDataPoint.fromMovisensHRData(data as MovisensHR));
}

/// A [Data] that holds an OMH [StepCount](https://pub.dev/documentation/openmhealth_schemas/latest/domain_omh_activity/StepCount-class.html)
class OMHStepCountDataPoint extends OMHMovisensDataPoint
    implements DataTransformerFactory {
  OMHStepCountDataPoint(super.datapoint);

  factory OMHStepCountDataPoint.fromMovisensStepCountData(
    MovisensStepCount data,
  ) {
    var steps = omh.StepCount(stepCount: data.steps)
      ..effectiveTimeFrame = (omh.TimeFrame()
        ..timeInterval = omh.TimeInterval(
          startDateTime: data.timestamp,
          endDateTime: data.timestamp,
        ));
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
        provenance: omh.DataPointAcquisitionProvenance(
          sourceName: source,
          modality: omh.DataPointModality.SENSED,
        ),
      ),
    );
  }

  factory OMHStepCountDataPoint.fromJson(Map<String, dynamic> json) =>
      OMHStepCountDataPoint(omh.DataPoint.fromJson(json));

  static DataTransformer get transformer => ((data) =>
      OMHStepCountDataPoint.fromMovisensStepCountData(
        data as MovisensStepCount,
      ));
}

/// A [Data] that holds an FHIR [Heart Rate Observation](http://hl7.org/fhir/heartrate.html).
class FHIRHeartRateObservation extends Data implements DataTransformerFactory {
  static const String DEFAULT_HR_UNIT = "beats/min";

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

    return FHIRHeartRateObservation(
      json.decode(fhirString) as Map<String, dynamic>,
    );
  }

  @override
  Map<String, dynamic> toJson() =>
      {Serializable.CLASS_IDENTIFIER: dataType}..addAll(fhirJson);

  factory FHIRHeartRateObservation.fromJson(Map<String, dynamic> json) =>
      FHIRHeartRateObservation(json);

  @override
  String get jsonType => "${NameSpace.FHIR}.observation-vitalsigns";

  static DataTransformer get transformer =>
      ((data) =>
          FHIRHeartRateObservation.fromMovisensHRData(data as MovisensHR));
}

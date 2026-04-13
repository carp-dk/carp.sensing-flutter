import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

import 'package:carp_serializable/carp_serializable.dart';
import 'package:carp_core/carp_core.dart' hide Smartphone;
import 'package:carp_mobile_sensing/carp_mobile_sensing.dart';
import 'package:carp_context_package/carp_context_package.dart';
import 'package:openmhealth_schemas/openmhealth_schemas.dart' as omh;

String _encode(Object object) =>
    const JsonEncoder.withIndent(' ').convert(object);

void main() {
  late StudyProtocol protocol;

  Future<void> writeToFile(String json, String fileName) async =>
      await File('test/json/$fileName').writeAsString(json);

  setUp(() {
    // Initialization of serialization
    CarpMobileSensing.ensureInitialized();
    ContextSamplingPackage().onRegister();

    // register the context sampling package
    SamplingPackageRegistry().register(ContextSamplingPackage());

    // Create a study protocol
    protocol = StudyProtocol(
      ownerId: 'owner@dtu.dk',
      name: 'Context Sensing Example',
    );

    // Define the smartphone as the primary device.
    Smartphone phone = Smartphone();
    protocol.addPrimaryDevice(phone);

    // Add a background task that collects activity data from the phone
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask()
        ..addMeasure(Measure(type: ContextSamplingPackage.ACTIVITY)),
      phone,
    );

    // Define the online location service and add it as a 'device'
    LocationService locationService = LocationService(
      accuracy: GeolocationAccuracy.low,
      distance: 10,
      interval: const Duration(minutes: 5),
    );
    protocol.addConnectedDevice(locationService, phone);

    // Add a background task that collects location on a regular basis
    protocol.addTaskControl(
      PeriodicTrigger(period: const Duration(minutes: 5)),
      BackgroundTask()
        ..addMeasure(Measure(type: ContextSamplingPackage.LOCATION)),
      locationService,
    );

    // Add a background task that continuously collects location and mobility
    // patterns. Delays sampling by 5 minutes.
    protocol.addTaskControl(
      DelayedTrigger(delay: const Duration(minutes: 5)),
      BackgroundTask()
        ..addMeasure(Measure(type: ContextSamplingPackage.LOCATION))
        ..addMeasure(Measure(type: ContextSamplingPackage.MOBILITY)),
      locationService,
    );

    // Add a background task that collects geofence events using DTU as the
    // center for the geofence.
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask()..addMeasure(
        Measure(type: ContextSamplingPackage.GEOFENCE)
          ..overrideSamplingConfiguration = GeofenceSamplingConfiguration(
            name: 'DTU',
            center: GeoPosition(55.786025, 12.524159),
            dwell: const Duration(minutes: 15),
            radius: 10.0,
          ),
      ),
      locationService,
    );

    // Define the online weather service and add it as a 'device'
    WeatherService weatherService = WeatherService(
      apiKey: 'OW_API_key_goes_here',
    );
    protocol.addConnectedDevice(weatherService, phone);

    // Add a background task that collects weather every 30 minutes.
    protocol.addTaskControl(
      PeriodicTrigger(period: const Duration(minutes: 30)),
      BackgroundTask()
        ..addMeasure(Measure(type: ContextSamplingPackage.WEATHER)),
      weatherService,
    );

    // Define the online air quality service and add it as a 'device'
    AirQualityService airQualityService = AirQualityService(
      apiKey: 'WAQI_API_key_goes_here',
    );
    protocol.addConnectedDevice(airQualityService, phone);

    // Add a background task that air quality every 30 minutes.
    protocol.addTaskControl(
      PeriodicTrigger(period: const Duration(minutes: 30)),
      BackgroundTask()
        ..addMeasure(Measure(type: ContextSamplingPackage.AIR_QUALITY)),
      airQualityService,
    );
  });

  test('CAMSStudyProtocol -> JSON', () async {
    expect(protocol, isNotNull);
    print(protocol);
    print(toJsonString(protocol));

    // used in the test below
    await writeToFile(toJsonString(protocol), 'protocol.json');
  });

  test('StudyProtocol -> JSON -> StudyProtocol :: deep assert', () async {
    print('#1 : $protocol');
    final studyJson = toJsonString(protocol);

    StudyProtocol protocolFromJson = StudyProtocol.fromJson(
      json.decode(studyJson) as Map<String, dynamic>,
    );
    expect(toJsonString(protocolFromJson), equals(studyJson));
    print('#2 : $protocolFromJson');
  });

  test('JSON File -> StudyProtocol', () async {
    String plainJson = File('test/json/protocol.json').readAsStringSync();

    StudyProtocol protocolFromFile = StudyProtocol.fromJson(
      json.decode(plainJson) as Map<String, dynamic>,
    );

    expect(protocolFromFile.ownerId, protocol.ownerId);
    expect(
      protocolFromFile.primaryDevices.first.roleName,
      Smartphone.DEFAULT_ROLE_NAME,
    );
    expect(protocolFromFile.taskControls.length, protocol.taskControls.length);
    print(toJsonString(protocolFromFile));
  });

  group('Data Types', () {
    test('- Context Data', () async {
      final allData = [
        Activity(type: ActivityType.WALKING, confidence: 100),
        AirQuality(
          airQualityIndex: 42,
          source: 'DMI',
          place: 'Copenhagen',
          latitude: 12.34,
          longitude: 56.78,
          airQualityLevel: AirQualityLevel.MODERATE,
        ),
        Geofence(type: GeofenceType.ENTER, name: 'DTU'),
        Location(longitude: 12.524159, latitude: 55.786025, altitude: 50.0),
        Mobility(numberOfPlaces: 5, homeStay: 80, distanceTraveled: 12000),
        Weather()
          ..areaName = 'Copenhagen'
          ..country = 'Denmark'
          ..temperature = 20.5
          ..weatherMain = 'Clear'
          ..weatherDescription = 'clear sky',
      ];

      for (var data in allData) {
        final dataJson = toJsonString(data);
        final dataFromJson = Function.apply(data.fromJsonFunction, [
          json.decode(dataJson) as Map<String, dynamic>,
        ]);
        print(toJsonString(dataFromJson));
        expect(toJsonString(dataFromJson), equals(dataJson));
      }
    });

    test('- OMH Data', () async {
      final allData = [
        OMHContextDataPoint(
          omh.DataPoint(
            body: omh.Measure(
              effectiveTimeFrame: omh.TimeFrame(dateTime: DateTime.now()),
            ),
          ),
        ),

        // The following does not work, since the omh package does not support
        // fromJson factory methods as polymorphic constructors.

        // OMHGeopositionDataPoint.fromLocationData(
        //   Location(longitude: 12.524159, latitude: 55.786025),
        // ),
        // OMHPhysicalActivityDataPoint.fromActivityData(
        //   Activity(type: ActivityType.RUNNING, confidence: 95),
        // ),
      ];

      for (var data in allData) {
        final dataJson = toJsonString(data);
        print(dataJson);
        final dataFromJson = Function.apply(data.fromJsonFunction, [
          json.decode(dataJson) as Map<String, dynamic>,
        ]);
        print(toJsonString(dataFromJson));
        expect(toJsonString(dataFromJson), equals(dataJson));
      }
    });
  });

  test('CARP Activity', () {
    Activity act = Activity(type: ActivityType.ON_BICYCLE, confidence: 90);
    Measurement m_1 = Measurement.fromData(act);
    expect(m_1.dataType.namespace, NameSpace.CARP);
    print(_encode(m_1));
  });

  test('CARP AirQuality', () {
    AirQuality air = AirQuality(
      airQualityIndex: 10,
      source: 'DMI',
      place: 'Copenhagen',
      latitude: 12,
      longitude: 3,
      airQualityLevel: AirQualityLevel.GOOD,
    );
    Measurement m_1 = Measurement.fromData(air);
    expect(m_1.dataType.namespace, NameSpace.CARP);
    print(_encode(m_1));
  });

  test('CARP Geofence', () {
    Geofence geo = Geofence(type: GeofenceType.DWELL, name: 'DTU');
    Measurement m_1 = Measurement.fromData(geo);
    expect(m_1.dataType.namespace, NameSpace.CARP);
    print(_encode(m_1));
  });

  test('CARP Location', () {
    Location loc = Location()
      ..longitude = 12.23342
      ..latitude = 3.34224
      ..altitude = 124.2134235;
    Measurement m_1 = Measurement.fromData(loc);
    expect(m_1.dataType.namespace, NameSpace.CARP);
    print(_encode(m_1));
  });

  test('CARP Mobility', () {
    Mobility mob = Mobility(
      numberOfPlaces: 2,
      homeStay: 86,
      distanceTraveled: 3400,
    );
    Measurement m_1 = Measurement.fromData(mob);
    expect(m_1.dataType.namespace, NameSpace.CARP);
    print(_encode(m_1));
  });

  test('CARP Weather', () {
    Weather wea = Weather()
      ..cloudiness = 0.3
      ..areaName = 'DTU';
    Measurement m_1 = Measurement.fromData(wea);
    expect(m_1.dataType.namespace, NameSpace.CARP);
    print(_encode(m_1));
  });
  test('CARP Location -> OMH Geoposition', () {
    Location loc = Location(longitude: 12.23342, latitude: 3.34224);
    Measurement m_1 = Measurement.fromData(loc);
    expect(m_1.dataType.namespace, NameSpace.CARP);
    print(_encode(loc));

    OMHGeopositionDataPoint geo =
        DataTransformerSchemaRegistry().lookup(NameSpace.OMH)!.transform(loc)
            as OMHGeopositionDataPoint;
    print(_encode(geo));

    Measurement m_2 = Measurement.fromData(geo);
    print(_encode(m_2));

    expect(m_2.dataType.namespace, NameSpace.OMH);
    expect(geo.datapoint.body, isA<omh.Geoposition>());
    var geopos = geo.datapoint.body as omh.Geoposition;
    expect(geopos.latitude.value, loc.latitude);
  });

  test('CARP Activity -> OMH Physical Activity', () {
    Activity act = Activity(type: ActivityType.WALKING, confidence: 100);
    Measurement m_1 = Measurement.fromData(act);
    expect(m_1.dataType.namespace, NameSpace.CARP);
    print(_encode(act));

    OMHPhysicalActivityDataPoint phy =
        DataTransformerSchemaRegistry().lookup(NameSpace.OMH)!.transform(act)
            as OMHPhysicalActivityDataPoint;
    print(_encode(phy));

    Measurement m_2 = Measurement.fromData(phy);
    print(_encode(m_2));

    expect(m_2.dataType.namespace, NameSpace.OMH);
    expect(phy.datapoint.body, isA<omh.PhysicalActivity>());
    var act_2 = phy.datapoint.body as omh.PhysicalActivity;
    expect(act_2.activityName, act.typeString);
  });

  test('Geofence', () {
    Geofence? d;
    GeoPosition home = GeoPosition(55.7946, 12.4472); // Parsbergsvej
    GeoPosition dtu = GeoPosition(55.786025, 12.524159); // DTU
    GeoPosition compute = GeoPosition(55.783499, 12.518914); // DTU Compute
    GeoPosition lyngby = GeoPosition(55.7704, 12.5038); // Kgs. Lyngby

    GeofenceSamplingConfiguration config = GeofenceSamplingConfiguration(
      name: 'Home',
      center: home,
      dwell: const Duration(minutes: 10),
      radius: 5,
    );

    CircularGeofence f = CircularGeofence.fromGeofenceSamplingConfiguration(
      config,
    )..dwell = const Duration(seconds: 2); // dwell timeout 2 secs.
    print(f);

    d = f.moved(home);
    print('starting from home - $d');
    expect(d!.type, GeofenceType.ENTER);

    d = f.moved(home);
    print('moved home - $d');
    expect(d, null);

    d = f.moved(dtu);
    print('moved to DTU - $d');
    expect(d!.type, GeofenceType.EXIT);

    d = f.moved(home);
    print('moved home - $d');
    expect(d!.type, GeofenceType.ENTER);

    d = f.moved(lyngby);
    print('moved to Lyngby - $d');
    expect(d!.type, GeofenceType.EXIT);

    d = f.moved(compute);
    print('moved to DTU Compute - $d');
    expect(d, null);

    d = f.moved(home);
    print('went home, sleeping - $d');
    sleep(const Duration(seconds: 3));
    d = f.moved(home);
    expect(d!.type, GeofenceType.DWELL);

    d = f.moved(compute);
    print('moved to DTU Compute - $d');
    expect(d!.type, GeofenceType.EXIT);
  });

  test('Mobility', () {});
}

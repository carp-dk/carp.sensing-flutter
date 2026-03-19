part of '../../main.dart';

class ProbeDescriptor {
  String name, description;
  Icon? icon;
  ProbeDescriptor(this.name, this.description, [this.icon]);
}

class ProbeDescription {
  static Map<String, ProbeDescriptor> get descriptors => {
    MonitoringSamplingPackage.ERROR: ProbeDescriptor(
      'Error',
      'Error.',
      Icon(Icons.error, size: 50, color: CachetColors.GREY_4),
    ),
    DeviceSamplingPackage.HEARTBEAT: ProbeDescriptor(
      'Heartbeat',
      'Device heartbeat.',
      Icon(Icons.important_devices_sharp, size: 50, color: CachetColors.GREY_4),
    ),
    MonitoringSamplingPackage.TRIGGERED_TASK: ProbeDescriptor(
      'Triggered Task',
      'Triggered Task',
      Icon(
        Icons.dashboard_customize_outlined,
        size: 50,
        color: CachetColors.GREY_4,
      ),
    ),
    MonitoringSamplingPackage.COMPLETED_TASK: ProbeDescriptor(
      'Completed Task',
      'Completed Task.',
      Icon(
        Icons.document_scanner_outlined,
        size: 50,
        color: CachetColors.GREY_4,
      ),
    ),
    MonitoringSamplingPackage.COMPLETED_APP_TASK: ProbeDescriptor(
      'Completed App Task',
      'Completed App Task.',
      Icon(
        Icons.document_scanner_outlined,
        size: 50,
        color: CachetColors.GREY_4,
      ),
    ),
    DeviceSamplingPackage.FREE_MEMORY: ProbeDescriptor(
      'Memory',
      'Free physical and virtual memory.',
      Icon(Icons.memory, size: 50, color: CachetColors.GREY_2),
    ),
    DeviceSamplingPackage.DEVICE_INFORMATION: ProbeDescriptor(
      'Device',
      'Information about this device (phone).',
      Icon(Icons.phone_android, size: 50, color: CachetColors.GREY_2),
    ),
    DeviceSamplingPackage.APPLICATION_INFORMATION: ProbeDescriptor(
      'Application',
      'Information about this application, incl. name.',
      Icon(Icons.settings_applications, size: 50, color: CachetColors.GREY_2),
    ),
    DeviceSamplingPackage.APP_LIFECYCLE_EVENT: ProbeDescriptor(
      'App Lifecycle Events',
      'App lifecycle events like foreground/background.',
      Icon(Icons.power_settings_new, size: 50, color: CachetColors.GREY_2),
    ),
    DeviceSamplingPackage.BATTERY_STATE: ProbeDescriptor(
      'Battery',
      'Battery level and charging status.',
      Icon(Icons.battery_charging_full, size: 50, color: CachetColors.GREEN),
    ),
    SensorSamplingPackage.STEP_EVENT: ProbeDescriptor(
      'Pedometer',
      'Step count events as steps are detected by the phone.',
      Icon(Icons.directions_walk, size: 50, color: CachetColors.LIGHT_PURPLE),
    ),
    SensorSamplingPackage.ACCELERATION: ProbeDescriptor(
      'Accelerometer',
      "Sensor data from the phone's onboard accelerometer.",
      Icon(Icons.adb, size: 50, color: CachetColors.GREY_2),
    ),
    SensorSamplingPackage.ROTATION: ProbeDescriptor(
      'Gyroscope',
      "Sensor data from the phone's onboard gyroscope.",
      Icon(Icons.adb, size: 50, color: CachetColors.GREY_2),
    ),
    SensorSamplingPackage.AMBIENT_LIGHT: ProbeDescriptor(
      'Light',
      'Measures ambient light in lux on a regular basis.',
      Icon(Icons.highlight, size: 50, color: CachetColors.YELLOW),
    ),
    ConnectivitySamplingPackage.BLUETOOTH: ProbeDescriptor(
      'Bluetooth',
      'Scans for nearby bluetooth devices on a regular basis.',
      Icon(Icons.bluetooth_searching, size: 50, color: CachetColors.DARK_BLUE),
    ),
    ConnectivitySamplingPackage.WIFI: ProbeDescriptor(
      'Wifi',
      'Collects names of connected wifi networks (SSID and BSSID)',
      Icon(Icons.wifi, size: 50, color: CachetColors.LIGHT_PURPLE),
    ),
    ConnectivitySamplingPackage.CONNECTIVITY: ProbeDescriptor(
      'Connectivity',
      'Information on connectivity status and mode.',
      Icon(Icons.cast_connected, size: 50, color: CachetColors.GREEN),
    ),
    MediaSamplingPackage.AUDIO: ProbeDescriptor(
      'Audio',
      'Ambient sound in the proximity of the phone.',
      Icon(Icons.mic, size: 50, color: CachetColors.ORANGE),
    ),
    MediaSamplingPackage.NOISE: ProbeDescriptor(
      'Noise',
      "Ambient noise level in decibel as detected by the phone's microphone.",
      Icon(Icons.hearing, size: 50, color: CachetColors.YELLOW),
    ),
    AppsSamplingPackage.APPS: ProbeDescriptor(
      'Apps',
      'Collects a list of installed apps.',
      Icon(Icons.apps, size: 50, color: CachetColors.LIGHT_GREEN),
    ),
    AppsSamplingPackage.APP_USAGE: ProbeDescriptor(
      'App Usage',
      'Collects app usage statistics.',
      Icon(Icons.get_app, size: 50, color: CachetColors.LIGHT_GREEN),
    ),
    CommunicationSamplingPackage.TEXT_MESSAGE_LOG: ProbeDescriptor(
      'Text Messages',
      'Collects the SMS message log.',
      Icon(Icons.textsms, size: 50, color: CachetColors.LIGHT_PURPLE),
    ),
    CommunicationSamplingPackage.TEXT_MESSAGE: ProbeDescriptor(
      'Text Message',
      'Collecting in/out-going SMS text messages.',
      Icon(Icons.text_fields, size: 50, color: CachetColors.LIGHT_PURPLE),
    ),
    CommunicationSamplingPackage.PHONE_LOG: ProbeDescriptor(
      'Phone Log',
      'Collects the phone call log.',
      Icon(Icons.phone_in_talk, size: 50, color: CachetColors.ORANGE),
    ),
    CommunicationSamplingPackage.CALENDAR: ProbeDescriptor(
      'Calendar',
      'Collects entries from phone calendars.',
      Icon(Icons.event, size: 50, color: CachetColors.CYAN),
    ),
    DeviceSamplingPackage.SCREEN_EVENT: ProbeDescriptor(
      'Screen',
      'Screen events (on/off/unlock).',
      Icon(
        Icons.screen_lock_portrait,
        size: 50,
        color: CachetColors.LIGHT_PURPLE,
      ),
    ),
    ContextSamplingPackage.LOCATION: ProbeDescriptor(
      'Location Tracking',
      "Continuous location tracking from the phone's GPS sensor.",
      Icon(Icons.location_on, size: 50, color: CachetColors.CYAN),
    ),
    ContextSamplingPackage.ACTIVITY: ProbeDescriptor(
      'Activity',
      'Physical activity as detected by the phone, e.g., sitting, walking, biking.',
      Icon(Icons.directions_bike, size: 50, color: CachetColors.ORANGE),
    ),
    ContextSamplingPackage.WEATHER: ProbeDescriptor(
      'Weather',
      'Collects local weather information.',
      Icon(Icons.cloud, size: 50, color: CachetColors.LIGHT_BLUE_2),
    ),
    ContextSamplingPackage.AIR_QUALITY: ProbeDescriptor(
      'Air Quality',
      'Collects local air quality information.',
      Icon(Icons.air, size: 50, color: CachetColors.GREY_3),
    ),
    ContextSamplingPackage.GEOFENCE: ProbeDescriptor(
      'Geofence',
      'Track movement in/out of a geographical ares (geofence).',
      Icon(Icons.share_location_outlined, size: 50, color: CachetColors.CYAN),
    ),
    ContextSamplingPackage.MOBILITY: ProbeDescriptor(
      'Mobility',
      'Mobility features calculated from location data.',
      Icon(Icons.mode_of_travel, size: 50, color: CachetColors.ORANGE),
    ),
    ESenseSamplingPackage.ESENSE_BUTTON: ProbeDescriptor(
      'eSense Button',
      'eSense button events.',
      Icon(
        Icons.radio_button_checked,
        size: 50,
        color: CachetColors.LIGHT_PURPLE,
      ),
    ),
    ESenseSamplingPackage.ESENSE_SENSOR: ProbeDescriptor(
      'eSense Movement',
      'eSense IMU sensor events.',
      Icon(Icons.headset, size: 50, color: CachetColors.LIGHT_PURPLE),
    ),
    PolarSamplingPackage.ACCELEROMETER: ProbeDescriptor(
      'Polar Accelerometer',
      'Polar IMU sensor events.',
      Icon(Icons.moving, size: 50, color: CachetColors.LIGHT_PURPLE),
    ),
    PolarSamplingPackage.GYROSCOPE: ProbeDescriptor(
      'Polar Gyroscope',
      'Polar IMU sensor events.',
      Icon(Icons.moving, size: 50, color: CachetColors.LIGHT_PURPLE),
    ),
    PolarSamplingPackage.MAGNETOMETER: ProbeDescriptor(
      'Polar Magnetometer',
      'Polar IMU sensor events.',
      Icon(Icons.iron, size: 50, color: CachetColors.LIGHT_PURPLE),
    ),
    PolarSamplingPackage.ECG: ProbeDescriptor(
      'Polar ECG',
      'Polar Electrocardiogram.',
      Icon(Icons.monitor_heart_rounded, size: 50, color: CachetColors.GREEN),
    ),
    PolarSamplingPackage.HR: ProbeDescriptor(
      'Polar HR',
      'Polar Heart Rate.',
      Icon(Icons.heart_broken, size: 50, color: CachetColors.RED),
    ),
    PolarSamplingPackage.PPG: ProbeDescriptor(
      'Polar PPG',
      'Polar Photoplethysmograpy.',
      Icon(Icons.add_link, size: 50, color: CachetColors.GREY_2),
    ),
    PolarSamplingPackage.PPI: ProbeDescriptor(
      'Polar PPI',
      'Polar Pulse-to-Pulse Interval.',
      Icon(Icons.link, size: 50, color: CachetColors.GREY_3),
    ),
    MovisensSamplingPackage.HR: ProbeDescriptor(
      'Movisens HR',
      'Movisens Heart Rate.',
      Icon(Icons.heart_broken, size: 50, color: CachetColors.CYAN),
    ),
    MovisensSamplingPackage.EDA: ProbeDescriptor(
      'Movisens EDA',
      'Movisens Electro Dermal Activity.',
      Icon(Icons.pin_drop, size: 50, color: CachetColors.CYAN),
    ),
    MovisensSamplingPackage.ACTIVITY: ProbeDescriptor(
      'Movisens Activity',
      'Movisens Activity Recognition.',
      Icon(Icons.directions_bike, size: 50, color: CachetColors.CYAN),
    ),
    MovisensSamplingPackage.RESPIRATION: ProbeDescriptor(
      'Movisens Respiration',
      'Movisens Respiration Rate.',
      Icon(Icons.air, size: 50, color: CachetColors.CYAN),
    ),
    MovisensSamplingPackage.SKIN_TEMPERATURE: ProbeDescriptor(
      'Movisens Skin Temperature',
      'Movisens Skin Temperature.',
      Icon(Icons.boy_rounded, size: 50, color: CachetColors.CYAN),
    ),
    MovisensSamplingPackage.TAP_MARKER: ProbeDescriptor(
      'Movisens Tap',
      'Movisens Tap Marker.',
      Icon(Icons.fingerprint, size: 50, color: CachetColors.CYAN),
    ),
    HealthSamplingPackage.HEALTH: ProbeDescriptor(
      'Health',
      'Health data collected from the phone.',
      Icon(Icons.heart_broken, size: 50, color: CachetColors.RED),
    ),
    // MovesenseSamplingPackage.HR: ProbeDescriptor(
    //   'Movesense HR',
    //   'Movesense Heart Rate.',
    //   Icon(Icons.heart_broken, size: 50, color: CachetColors.CYAN),
    // ),
    // MovesenseSamplingPackage.ECG: ProbeDescriptor(
    //   'Movesense ECG',
    //   'Movesense Electrocardiogram.',
    //   Icon(Icons.monitor_heart_rounded,
    //       size: 50, color: CachetColors.GREEN),
    // ),
    // MovesenseSamplingPackage.TEMPERATURE: ProbeDescriptor(
    //   'Movesense Skin Temperature',
    //   'Movesense Skin Temperature.',
    //   Icon(Icons.boy_rounded, size: 50, color: CachetColors.CYAN),
    // ),
    // MovesenseSamplingPackage.STATE: ProbeDescriptor(
    //   'Movesense State',
    //   'Movesense Tap Marker.',
    //   Icon(Icons.fingerprint, size: 50, color: CachetColors.CYAN),
    // ),
    // MovesenseSamplingPackage.IMU: ProbeDescriptor(
    //   'Movesense Movement',
    //   'Movesense Inertial Movement Unit (IMU).',
    //   Icon(Icons.moving, size: 50, color: CachetColors.CYAN),
    // ),
    // CortriumSamplingPackage.ECG: ProbeDescriptor(
    //   'C3+ ECG',
    //   'C3+ Electrocardiogram.',
    //   Icon(Icons.monitor_heart_rounded, size: 50, color: CachetColors.BLUE),
    // ),
  };

  static Map<ExecutorState, String> get probeStateLabel => {
    ExecutorState.Created: "Created",
    ExecutorState.Initialized: "Initialized",
    ExecutorState.Resumed: "Resumed",
    ExecutorState.Paused: "Paused",
    ExecutorState.Undefined: "Undefined",
  };

  static Map<ExecutorState, Icon> get probeStateIcon => {
    ExecutorState.Created: Icon(Icons.child_care, color: CachetColors.GREY_4),
    ExecutorState.Initialized: Icon(
      Icons.check,
      color: CachetColors.LIGHT_PURPLE,
    ),
    ExecutorState.Resumed: Icon(
      Icons.radio_button_checked,
      color: CachetColors.GREEN,
    ),
    ExecutorState.Paused: Icon(
      Icons.radio_button_unchecked,
      color: CachetColors.GREEN,
    ),
    ExecutorState.Undefined: Icon(Icons.error_outline, color: CachetColors.RED),
  };
}

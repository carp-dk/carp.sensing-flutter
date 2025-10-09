part of '../../main.dart';

/// Contains static information about a device type.
class DeviceTypeDescriptor {
  String? name, description;
  Icon? icon;
  DeviceTypeDescriptor(this.name, [this.description, this.icon]);
}

class DeviceDescription {
  static Map<String, DeviceTypeDescriptor> get descriptors => {
        Smartphone.DEVICE_TYPE: DeviceTypeDescriptor('Phone', 'This phone',
            Icon(Icons.phone_android, size: 50, color: CachetColors.GREY_4)),
        ESenseDevice.DEVICE_TYPE: DeviceTypeDescriptor(
            'eSense',
            'eSense Ear Plug',
            Icon(Icons.headset, size: 50, color: CachetColors.BLUE)),
        PolarDevice.DEVICE_TYPE: DeviceTypeDescriptor(
            'Polar',
            'Polar HR Monitor',
            Icon(Icons.monitor_heart,
                size: 50, color: CachetColors.LIGHT_GREEN)),
        LocationService.DEVICE_TYPE: DeviceTypeDescriptor(
            'Location',
            'Location Service',
            Icon(Icons.location_on, size: 50, color: CachetColors.GREEN)),
        AirQualityService.DEVICE_TYPE: DeviceTypeDescriptor(
            'Air Quality',
            'World Air Quality Service',
            Icon(Icons.air, size: 50, color: CachetColors.LIGHT_GREEN)),
        WeatherService.DEVICE_TYPE: DeviceTypeDescriptor(
            'Weather',
            'Open Weather Service',
            Icon(Icons.cloud, size: 50, color: CachetColors.DARK_BLUE)),
        HealthService.DEVICE_TYPE: DeviceTypeDescriptor(
            'Health',
            'Health data stored on the phone',
            Icon(Icons.heart_broken, size: 50, color: CachetColors.RED)),
        MovisensDevice.DEVICE_TYPE: DeviceTypeDescriptor(
            'Movisens',
            'Movisens Sensor',
            Icon(Icons.watch, size: 50, color: CachetColors.CYAN)),
        // MovesenseDevice.DEVICE_TYPE: DeviceTypeDescriptor(
        //     'Movesense',
        //     'Movesense ECG Sensor',
        //     Icon(Icons.watch, size: 50, color: CachetColors.CYAN)),
        // CortriumDevice.DEVICE_TYPE: DeviceTypeDescriptor(
        //     'Cortrium',
        //     'Cortrium ECG Holter Monitor',
        //     Icon(Icons.monitor_heart, size: 50, color: CachetColors.CYAN)),
      };

  static Map<DeviceStatus, Icon> get deviceStateIcon => {
        DeviceStatus.unknown:
            Icon(Icons.error_outline, color: CachetColors.RED),
        DeviceStatus.error: Icon(Icons.error_outline, color: CachetColors.RED),
        DeviceStatus.disconnected:
            Icon(Icons.close, color: CachetColors.YELLOW),
        DeviceStatus.connected: Icon(Icons.check, color: CachetColors.GREEN),
        DeviceStatus.paired:
            Icon(Icons.bluetooth_connected, color: CachetColors.DARK_BLUE),
      };
}

part of '../connectivity.dart';

/// Anonymizes a [Bluetooth] scan by hashing (SHA-1) the device and
/// advertisement names of each device found.
///
/// Bluetooth device names may contain participants' real names because people
/// use their names to name their computers and phones. Registered in the
/// default [PrivacySchema] for the [ConnectivitySamplingPackage.BLUETOOTH] measure.
Data bluetoothNameAnonymizer(Data data) {
  assert(data is Bluetooth);
  Bluetooth bt = data as Bluetooth;
  for (var result in bt.scanResult) {
    result.bluetoothDeviceName = sha1
        .convert(utf8.encode(result.bluetoothDeviceName))
        .toString();
    result.advertisementName = sha1
        .convert(utf8.encode(result.advertisementName))
        .toString();
  }
  return bt;
}

/// Anonymizes [Wifi] data by hashing (SHA-1) the network name (SSID).
///
/// Wifi network names may contain participants' or households' real names.
/// Registered in the default [PrivacySchema] for the
/// [ConnectivitySamplingPackage.WIFI] measure.
Data wifiNameAnonymizer(Data data) {
  assert(data is Wifi);
  Wifi wd = data as Wifi;
  return wd
    ..ssid = (wd.ssid != null)
        ? sha1.convert(utf8.encode(wd.ssid!)).toString()
        : wd.ssid;
}

part of '../connectivity.dart';

/// A [Bluetooth] anonymizer function. Anonymizes the name and discovery
/// name of each discovered bluetooth device.
/// Bluetooth devices' names may contain participants' real name because people
/// use their names to name their computers and phones.
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

/// A [Wifi] anonymizer function. Anonymizes the wifi name (SSID) of the
/// wifi network. Wifi network names may contain participants' or house holds'
/// real name because people use their names to name their wifi.
Data wifiNameAnonymizer(Data data) {
  assert(data is Wifi);
  Wifi wd = data as Wifi;
  return wd
    ..ssid = (wd.ssid != null)
        ? sha1.convert(utf8.encode(wd.ssid!)).toString()
        : wd.ssid;
}

# Example usage of the BLE Device Scanner

 The BLEScannerPage provides a complete UI for scanning and selecting BLE devices.

 Usage Example:

 ```dart
 // Open the BLE scanner and wait for device selection
 final selectedDevice = await Navigator.of(context).push<DiscoveredDevice?>(
   MaterialPageRoute(
     builder: (context) => BLEScannerPage(),
   ),
 );
 
 if (selectedDevice != null) {
   print('Selected device: ${selectedDevice.name} (${selectedDevice.id})');
   // Use the selected device for further operations
 } else {
   print('Scan was cancelled');
 }
 ```

 Features:

- Real-time scanning for BLE devices using FlutterReactiveBle
- Displays device name, address (MAC), and RSSI signal strength
- Shows number of services available on each device
- Prevents duplicate devices in the list (updates RSSI instead)
- Allows user to cancel at any time
- Returns a DiscoveredDevice object when a device is selected
- Shows error dialogs if scanning fails
- Rescan button to restart scanning

 BLEScannerPage Properties:

- Device List: Shows all discovered devices with their details
- RSSI Indicator: Signal strength in dBm
- Service Count: Number of available services on device
- Rescan Button: Restart the device scan
- Device Count: Shows total number of devices found

 Device Selection Flow:

 1. User navigates to BLEScannerPage
 2. Scan starts automatically
 3. Devices appear in the list as they are discovered
 4. User can tap a device to select it
 5. The view closes and returns the selected DiscoveredDevice
 6. Or user can cancel with the back button to get null

 Integration with your app:
 You can integrate this into your device configuration flow:

 ```dart
 // In your configuration page
 ElevatedButton(
   onPressed: () async {
     final device = await Navigator.of(context).push<DiscoveredDevice?>(
       MaterialPageRoute(builder: (context) => BLEScannerPage()),
     );
     if (device != null) {
       setState(() {
         _selectedDevice = device;
       });
     }
   },
   child: const Text('Scan for BLE Device'),
 )
 ```

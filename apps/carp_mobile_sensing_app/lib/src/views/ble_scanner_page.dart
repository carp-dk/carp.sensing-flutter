part of '../../main.dart';

/// A view that scans for BLE devices and allows the user to select one.
/// This view uses [ble.FlutterReactiveBle] to scan for available BLE devices
/// and displays them in a list.
///
///  Usage Example:
///
///  ```dart
///  // Open the BLE scanner and wait for device selection
///  final selectedDevice = await Navigator.of(context).push<DiscoveredDevice?>(
///    MaterialPageRoute(
///      builder: (context) => BLEScannerPage(),
///    ),
///  );
///
///  if (selectedDevice != null) {
///    print('Selected device: ${selectedDevice.name} (${selectedDevice.id})');
///    // Use the selected device for further operations
///  } else {
///    print('Scan was cancelled');
///  }
///  ```
///
///  Features:
///
/// - Real-time scanning for BLE devices using FlutterReactiveBle
/// - Displays device name, address (MAC), and RSSI signal strength
/// - Shows number of services available on each device
/// - Prevents duplicate devices in the list (updates RSSI instead)
/// - Allows user to cancel at any time
/// - Returns a DiscoveredDevice object when a device is selected
/// - Shows error dialogs if scanning fails
/// - Rescan button to restart scanning
///
class BLEScannerPage extends StatefulWidget {
  final ble.FlutterReactiveBle plugin;
  final BLEDevice? configuration;

  BLEScannerPage({ble.FlutterReactiveBle? plugin, this.configuration})
    : plugin = plugin ?? ble.FlutterReactiveBle();

  @override
  BLEScannerPageState createState() => BLEScannerPageState();
}

class BLEScannerPageState extends State<BLEScannerPage> {
  late StreamSubscription<ble.DiscoveredDevice> _scanStream;
  final List<ble.DiscoveredDevice> _discoveredDevices = [];
  bool _isScanning = false;

  ble.FlutterReactiveBle get plugin => widget.plugin;
  BLEDevice? get configuration => widget.configuration;
  List<ble.Uuid> get serviceUuids =>
      configuration?.serviceUuids.map((str) => ble.Uuid.parse(str)).toList() ??
      [];

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  @override
  void dispose() {
    _scanStream.cancel();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _discoveredDevices.clear();
    });

    _scanStream = plugin
        .scanForDevices(withServices: serviceUuids)
        .listen(
          (device) {
            // Avoid duplicates
            final index = _discoveredDevices.indexWhere(
              (d) => d.id == device.id,
            );

            if (index >= 0) {
              // Update existing device with new RSSI value
              _discoveredDevices[index] = device;
            } else {
              // Add new device if it matches the RSSI and name criteria
              if (device.rssi > (configuration?.minRssi ?? -80) &&
                  device.name.startsWith(configuration?.namePrefix ?? '')) {
                _discoveredDevices.add(device);
              }
            }

            setState(() {});
          },
          onError: (dynamic error) {
            _showErrorDialog(error.toString());
          },
        );
  }

  void _stopScan() {
    _scanStream.cancel();
    setState(() {
      _isScanning = false;
    });
  }

  void _selectDevice(ble.DiscoveredDevice device) {
    _stopScan();
    Navigator.of(context).pop(device);
  }

  void _cancelScan() {
    _stopScan();
    Navigator.of(context).pop();
  }

  void _showErrorDialog(String message) {
    showDialog<ble.DiscoveredDevice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Scan for BLE Devices'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _cancelScan,
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Devices found: ${_discoveredDevices.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (_isScanning)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _startScan,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Rescan'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _discoveredDevices.isEmpty
                ? Center(
                    child: Text(
                      _isScanning
                          ? 'Scanning for devices...'
                          : 'No devices found',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : Scrollbar(
                    child: ListView.builder(
                      itemCount: _discoveredDevices.length,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemBuilder: (context, index) =>
                          _buildDeviceCard(context, _discoveredDevices[index]),
                    ),
                  ),
          ),
        ],
      ),
    ),
  );

  Widget _buildDeviceCard(BuildContext context, ble.DiscoveredDevice device) =>
      Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(
            device.name.isNotEmpty ? device.name : 'Unknown Device',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                'Address: ${device.id}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'RSSI: ${device.rssi} dBm',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (device.serviceUuids.isNotEmpty)
                Text(
                  'Services: ${device.serviceUuids.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          isThreeLine: true,
          trailing: const Icon(Icons.arrow_forward),
          onTap: () => _selectDevice(device),
        ),
      );
}

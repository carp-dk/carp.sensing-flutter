part of '../../main.dart';

class DevicesListPage extends StatefulWidget {
  final DeviceListViewModel _deviceListViewModel;
  DevicesListPage(this._deviceListViewModel);

  @override
  DevicesListPageState createState() => DevicesListPageState();
}

class DevicesListPageState extends State<DevicesListPage> {
  DeviceListViewModel get model => widget._deviceListViewModel;

  @override
  Widget build(BuildContext context) {
    List<DeviceViewModel> devices = model.deployedDevices.toList();

    return Scaffold(
      appBar: AppBar(title: Text('Devices')),
      body: Scrollbar(
        child: ListView.builder(
          itemCount: devices.length,
          padding: EdgeInsets.symmetric(vertical: 8.0),
          itemBuilder: (context, index) => _deviceCard(context, devices[index]),
        ),
      ),
    );
  }

  Widget _deviceCard(BuildContext context, DeviceViewModel device) {
    return Center(
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: StreamBuilder<DeviceStatus>(
          stream: device.deviceEvents,
          initialData: DeviceStatus.unknown,
          builder: (context, AsyncSnapshot<DeviceStatus> snapshot) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: device.icon,
                title: Text(device.typeName),
                subtitle: Text(device.description),
                trailing: device.status == DeviceStatus.connecting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            CachetColors.BLUE,
                          ),
                        ),
                      )
                    : device.stateIcon,
              ),
              FutureBuilder<bool>(
                future: device.deviceManager.hasPermissions(),
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  final hasPermissions = snapshot.data ?? true;
                  final showPermissionButton = !hasPermissions;
                  final showScanButton =
                      hasPermissions &&
                      device.isBleDevice &&
                      device.status.index < DeviceStatus.paired.index;
                  final showConnectButton =
                      hasPermissions &&
                      (device.status == DeviceStatus.paired ||
                          device.status == DeviceStatus.disconnected);

                  if (!showPermissionButton &&
                      !showScanButton &&
                      !showConnectButton) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    children: [
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: [
                            if (showPermissionButton)
                              ElevatedButton(
                                onPressed: () =>
                                    device.deviceManager.requestPermissions(),
                                child: const Text('Request Permissions'),
                              ),
                            if (showScanButton)
                              ElevatedButton(
                                onPressed: () async {
                                  final selectedDevice =
                                      await Navigator.of(
                                        context,
                                      ).push<ble.DiscoveredDevice?>(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BLEScannerPage(),
                                        ),
                                      );
                                  if (selectedDevice != null) {
                                    setState(() {
                                      device.pairWithDevice(selectedDevice);
                                    });
                                  }
                                },
                                child: const Text('Scan for Devices'),
                              ),
                            if (showConnectButton)
                              ElevatedButton(
                                onPressed: () => device.connectToDevice(),
                                child: const Text('Connect'),
                              ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

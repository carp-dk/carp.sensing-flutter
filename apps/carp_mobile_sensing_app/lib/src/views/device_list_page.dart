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
                title: Text(device.id),
                subtitle: Text(device.description),
                trailing: device.stateIcon,
              ),
              // const Divider(),
              // TextButton(
              //     child: const Text('How to use this device?'),
              //     onPressed: () => print('Use the $device')),
              FutureBuilder<bool>(
                future: device.deviceManager.hasPermissions(),
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  Widget w = Text("");

                  if (snapshot.hasData && !snapshot.data!) {
                    w = Column(
                      children: [
                        const Divider(),
                        TextButton(
                          child: const Text(
                            'Request permissions to access this device',
                          ),
                          onPressed: () =>
                              device.deviceManager.requestPermissions(),
                        ),
                      ],
                    );
                  }
                  return w;
                },
              ),
              (device.status != DeviceStatus.connected)
                  ? Column(
                      children: [
                        const Divider(),
                        TextButton(
                          child: const Text('Connect to this device'),
                          onPressed: () => device.connectToDevice(),
                        ),
                      ],
                    )
                  : Text(""),
            ],
          ),
        ),
      ),
    );
  }
}

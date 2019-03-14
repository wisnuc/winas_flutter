import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';

import '../common/utils.dart';
import '../common/request.dart';

const LOCAL_AUTH_SERVICE = '60000000-0182-406c-9221-0a6680bd0943';
const LOCAL_AUTH_SERVICE_INDICATE = '60000001-0182-406c-9221-0a6680bd0943';
const LOCAL_AUTH_SERVICE_WRITE = '60000002-0182-406c-9221-0a6680bd0943';
const NET_SETTING_SERVICE = '70000000-0182-406c-9221-0a6680bd0943';
const NET_SETTING_SERVICE_INDICATE = '70000001-0182-406c-9221-0a6680bd0943';
const NET_SETTING_SERVICE_WRITE = '70000002-0182-406c-9221-0a6680bd0943';
const CLOUD_SERVICE = '80000000-0182-406c-9221-0a6680bd0943';
const CLOUD_SERVICE_INDICATE = '80000001-0182-406c-9221-0a6680bd0943';
const CLOUD_SERVICE_WRITE = '80000002-0182-406c-9221-0a6680bd0943';

class AddDevice extends StatefulWidget {
  AddDevice({Key key}) : super(key: key);
  @override
  _AddDeviceState createState() => _AddDeviceState();
}

class _AddDeviceState extends State<AddDevice> {
  Request request = Request();
  StreamSubscription<ScanResult> scanSubscription;
  StreamSubscription<BluetoothDeviceState> deviceConnection;
  ScrollController myScrollController = ScrollController();
  @override
  void initState() {
    super.initState();
    startBLESearch();
  }

  @override
  void dispose() {
    super.dispose();
    scanSubscription.cancel();

    /// Disconnect from device
    deviceConnection.cancel();
  }

  List<ScanResult> results = [];

  startBLESearch() async {
    FlutterBlue flutterBlue = FlutterBlue.instance;
    scanSubscription?.cancel();
    scanSubscription = flutterBlue.scan().listen((scanResult) {
      if (scanResult.device.name.length == 0) return;
      // if (!scanResult.device.name.startsWith('W')) return;
      final id = scanResult.device.id;
      int index = results.indexWhere((res) => res.device.id == id);
      if (index > -1) return;

      results.add(scanResult);
      print(id);
      print(scanResult.device.name);
      print(scanResult.advertisementData.localName);
      print(scanResult.advertisementData.manufacturerData);
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future getLocalAuth(
      BluetoothDevice device, List<BluetoothService> services) async {
    final localAuthService = services.firstWhere(
      (s) => s.uuid.toString() == LOCAL_AUTH_SERVICE,
      orElse: () => null,
    );

    final localAuthNotify = localAuthService.characteristics.firstWhere(
      (c) => c.uuid.toString() == LOCAL_AUTH_SERVICE_INDICATE,
      orElse: () => null,
    );

    final localAuthWrite = localAuthService.characteristics.firstWhere(
      (c) => c.uuid.toString() == LOCAL_AUTH_SERVICE_WRITE,
      orElse: () => null,
    );
    await device.setNotifyValue(localAuthNotify, true);
    return {
      'service': localAuthService,
      'notify': localAuthNotify,
      'write': localAuthWrite,
    };
  }

  writeData(
    String data,
    BluetoothDevice device,
    BluetoothCharacteristic notifyCharact,
    BluetoothCharacteristic writeCharact,
    Function callback,
  ) {
    bool fired = false;

    device.onValueChanged(notifyCharact).first.then((value) {
      if (!fired) {
        fired = true;
        final res = String.fromCharCodes(value);

        callback(null, res);
      }
    });

    device
        .writeCharacteristic(writeCharact, data.codeUnits)
        .catchError((error) {
      if (!fired) {
        fired = true;
        callback(error, null);
      }
    });
  }

  Future writeDataAsync(
    String data,
    BluetoothDevice device,
    BluetoothCharacteristic notifyCharact,
    BluetoothCharacteristic writeCharact,
  ) async {
    Completer c = Completer();
    writeData(data, device, notifyCharact, writeCharact, (error, value) {
      if (error != null) {
        c.completeError(error);
      } else {
        c.complete(value);
      }
    });
    return c.future;
  }

  auth(BluetoothDevice device, List<BluetoothService> services) async {
    final localAuthService = services.firstWhere(
      (s) => s.uuid.toString() == LOCAL_AUTH_SERVICE,
      orElse: () => null,
    );

    final localAuthNotify = localAuthService.characteristics.firstWhere(
      (c) => c.uuid.toString() == LOCAL_AUTH_SERVICE_INDICATE,
      orElse: () => null,
    );

    final localAuthWrite = localAuthService.characteristics.firstWhere(
      (c) => c.uuid.toString() == LOCAL_AUTH_SERVICE_WRITE,
      orElse: () => null,
    );
    await device.setNotifyValue(localAuthNotify, true);

    device.onValueChanged(localAuthNotify).listen((value) {
      final res = String.fromCharCodes(value);
      print(res);
    });

    final s1 = '{"action":"req","seq":1}';

    await device.writeCharacteristic(localAuthWrite, s1.codeUnits);

    await Future.delayed(Duration(seconds: 2));

    final s2 = '{"action":"auth","seq":2}';

    await device.writeCharacteristic(localAuthWrite, s2.codeUnits);
  }

  connect(ScanResult scanResult) {
    final device = scanResult.device;
    FlutterBlue flutterBlue = FlutterBlue.instance;
    deviceConnection?.cancel();
    print('connecting ${scanResult.device.name} ...');
    showLoading(context);
    deviceConnection = flutterBlue
        .connect(device, timeout: Duration(seconds: 60), autoConnect: false)
        .listen((s) async {
      print(s);
      if (s == BluetoothDeviceState.connected) {
        // device is connected, do something
        List<BluetoothService> services = await device.discoverServices();
        // await auth(device, services);

        // final localAuthService = services.firstWhere(
        //   (s) => s.uuid.toString() == NET_SETTING_SERVICE,
        //   orElse: () => null,
        // );

        // final localAuthNotify = localAuthService.characteristics.firstWhere(
        //   (c) => c.uuid.toString() == NET_SETTING_SERVICE_INDICATE,
        //   orElse: () => null,
        // );

        // final localAuthWrite = localAuthService.characteristics.firstWhere(
        //   (c) => c.uuid.toString() == NET_SETTING_SERVICE_WRITE,
        //   orElse: () => null,
        // );
        // await device.setNotifyValue(localAuthNotify, true);
        // device.onValueChanged(localAuthNotify).listen((value) {
        //   final res = String.fromCharCodes(value);
        //   print('res:\n$res');
        // });

        // final s1 =
        //     '{"action":"addAndActive", "seq": 123, "token": "0bf6abac423c54540a713870d54b16446fc8442a65e3a3bd2a1d7126f139b95c04368c83988381627284f7c561809ea2", "body":{"ssid":"Naxian800", "pwd":"vpai1228"}}';

        // await device.writeCharacteristic(localAuthWrite, s1.codeUnits);
      }
      Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: DraggableScrollbar.semicircle(
        controller: myScrollController,
        child: CustomScrollView(
          controller: myScrollController,
          physics: AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            // AppBar，包含一个导航栏
            SliverAppBar(
              pinned: true,
              expandedHeight: 128.0,
              elevation: 0.0, // no shadow
              backgroundColor: Colors.white,
              brightness: Brightness.light,
              iconTheme: IconThemeData(color: Colors.black38),
              // title: Text(
              //   '发现设备2',
              //   style: TextStyle(color: Colors.black87),
              // ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsetsDirectional.only(start: 16, bottom: 16),
                title: Text(
                  '发现设备',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ),

            // List
            SliverFixedExtentList(
              itemExtent: 50.0,
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  ScanResult scanResult = results[index];
                  return Material(
                    child: InkWell(
                      onTap: () {
                        connect(scanResult);
                      },
                      child: Container(
                        height: 64,
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: <Widget>[
                            Text(
                              scanResult.device.name,
                              style: TextStyle(fontSize: 21),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(),
                            ),
                            Text(
                              '待配置',
                              style: TextStyle(color: Colors.black54),
                            ),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                childCount: results.length,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

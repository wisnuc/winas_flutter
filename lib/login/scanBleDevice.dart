import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';

import './ble.dart';
import './configDevice.dart';
import '../common/utils.dart';
import '../common/request.dart';

class ScanBleDevice extends StatefulWidget {
  ScanBleDevice({Key key}) : super(key: key);
  @override
  _ScanBleDeviceState createState() => _ScanBleDeviceState();
}

class _ScanBleDeviceState extends State<ScanBleDevice> {
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
    scanSubscription?.cancel();

    /// Disconnect from device
    deviceConnection?.cancel();
  }

  List<ScanResult> results = [];

  Future startBLESearch() async {
    FlutterBlue flutterBlue = FlutterBlue.instance;
    scanSubscription?.cancel();
    scanSubscription = flutterBlue.scan().listen((scanResult) {
      if (scanResult.device.name.length == 0) return;
      // if (!scanResult.device.name.startsWith('W')) return;
      final id = scanResult.device.id;
      int index = results.indexWhere((res) => res.device.id == id);
      if (index > -1) return;
      results.add(scanResult);
      print('get device >>>>>>>>>>>');
      print(id);
      print(scanResult.device.name);
      print(scanResult.advertisementData.localName);
      print(scanResult.advertisementData.manufacturerData);
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// send a auth request, make device flash light (show color code)
  Future reqAuth(BluetoothDevice device) async {
    final reqCommand = '{"action":"req","seq":1}';
    // get color code list TODO: check station API
    final res = await getLocalAuth(device, reqCommand);
    print('reqAuth: $res');
  }

  /// connect to selected BLE device
  void connect(ScanResult scanResult, Function callback) {
    final device = scanResult.device;
    FlutterBlue flutterBlue = FlutterBlue.instance;
    // cancel previous BLE device connection
    deviceConnection?.cancel();
    print('connecting ${scanResult.device.name} ...');
    showLoading(context);
    deviceConnection = flutterBlue
        .connect(device, timeout: Duration(seconds: 60), autoConnect: false)
        .listen((s) {
      print(s);

      Navigator.pop(context);
      if (s == BluetoothDeviceState.connected) {
        callback(null, device);
      } else {
        callback('Disconnected', null);
      }
    });
  }

  /// async function of `connect`
  Future<BluetoothDevice> connectAsync(ScanResult scanResult) async {
    Completer<BluetoothDevice> c = Completer();
    connect(scanResult, (error, BluetoothDevice value) {
      if (error != null) {
        c.completeError(error);
      } else {
        c.complete(value);
      }
    });
    return c.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (BuildContext ctx) {
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
                    titlePadding:
                        EdgeInsetsDirectional.only(start: 16, bottom: 16),
                    title: Text(
                      '发现设备',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ),
                ),

                // List
                SliverFixedExtentList(
                  itemExtent: 48.0,
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      ScanResult scanResult = results[index];
                      return Material(
                        child: InkWell(
                          onTap: () async {
                            BluetoothDevice device;
                            try {
                              device = await connectAsync(scanResult);
                            } catch (e) {
                              print(e);
                              showSnackBar(ctx, '连接设备失败');
                              return;
                            }

                            try {
                              await reqAuth(device);
                            } catch (e) {
                              print(e);
                              showSnackBar(ctx, '请求设备验证失败');
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ConfigDevice(device: device),
                              ),
                            );
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
      }),
    );
  }
}

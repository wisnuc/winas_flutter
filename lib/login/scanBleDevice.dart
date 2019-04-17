import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';

import './ble.dart';
import './configDevice.dart';
import '../common/utils.dart';
import '../common/request.dart';

class ScanBleDevice extends StatefulWidget {
  ScanBleDevice({Key key, this.request, this.action}) : super(key: key);
  final Request request;
  final Action action;
  @override
  _ScanBleDeviceState createState() => _ScanBleDeviceState();
}

class _ScanBleDeviceState extends State<ScanBleDevice> {
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
      // if (scanResult.device.name.length == 0) return;
      if (!scanResult.device.name.toLowerCase().startsWith('wi')) return;
      final id = scanResult.device.id;
      int index = results.indexWhere((res) => res.device.id == id);
      if (index > -1) return;

      results.add(scanResult);

      // for (var i = 0; i < 100; i++) {
      //   results.add(scanResult);
      // }

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
    // TODO: get color code list
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
    bool done = false;
    deviceConnection = flutterBlue
        .connect(device, timeout: Duration(seconds: 60), autoConnect: false)
        .listen((s) {
      print(s);
      if (done) return;
      if (s == BluetoothDeviceState.connected) {
        done = true;
        callback(null, device);
      } else {
        done = true;
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

  parseResult(ScanResult scanResult) {
    final manufacturerData = scanResult.advertisementData.manufacturerData;
    final value = manufacturerData[65535][0];
    String status = '';
    switch (value) {
      case 1:
        status = '待配置';
        break;

      case 2:
        status = '已绑定';
        break;

      default:
        status = '设备异常';
    }
    bool enabled = widget.action == Action.wifi || value == 1;
    return {
      'status': status,
      'enabled': enabled,
    };
  }

  @override
  Widget build(BuildContext context) {
    bool noResult = results.length == 0;

    return Scaffold(
      appBar: AppBar(
        elevation: 0.0, // no shadow
        brightness: Brightness.light,
        backgroundColor: Colors.grey[50],
        iconTheme: IconThemeData(color: Colors.black38),
        title: Text(
          '蓝牙扫描设备',
          style: TextStyle(color: Colors.black87),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                results.clear();
              });
              startBLESearch();
            },
          )
        ],
      ),
      body: Builder(builder: (BuildContext ctx) {
        return Container(
          color: Colors.grey[50],
          child: CustomScrollView(
            controller: myScrollController,
            physics: AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              // List
              SliverFixedExtentList(
                itemExtent: noResult ? 256 : 64,
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    // no result, show loading
                    if (noResult) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    ScanResult scanResult = results[index];
                    final res = parseResult(scanResult);
                    final status = res['status'];
                    final enabled = res['enabled'];

                    return Material(
                      child: InkWell(
                        onTap: () async {
                          if (!enabled) return;

                          BluetoothDevice device;
                          showLoading(context);
                          try {
                            device = await connectAsync(scanResult);
                          } catch (e) {
                            print(e);
                            Navigator.pop(context);
                            showSnackBar(ctx, '连接设备失败');
                            return;
                          }

                          try {
                            await reqAuth(device);
                          } catch (e) {
                            print(e);
                            Navigator.pop(context);
                            showSnackBar(ctx, '请求设备验证失败');
                            return;
                          }
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ConfigDevice(
                                    device: device,
                                    request: widget.request,
                                    action: widget.action,
                                  ),
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
                                status,
                                style: TextStyle(color: Colors.black54),
                              ),
                              Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: noResult ? 1 : results.length,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

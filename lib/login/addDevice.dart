import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';

import '../common/request.dart';

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
      if (!scanResult.device.name.startsWith('W')) return;
      final id = scanResult.device.id;
      int index = results.indexWhere((res) => res.device.id == id);
      if (index > -1) return;

      results.add(scanResult);
      print(id);
      print(scanResult.device.name);
      if (mounted) {
        setState(() {});
      }
    });
  }

  connect(ScanResult scanResult) {
    final device = scanResult.device;
    FlutterBlue flutterBlue = FlutterBlue.instance;
    deviceConnection?.cancel();
    deviceConnection =
        flutterBlue.connect(device, autoConnect: false).listen((s) async {
      print(s);
      if (s == BluetoothDeviceState.connected) {
        // device is connected, do something
        List<BluetoothService> services = await device.discoverServices();
        services.forEach((service) {
          // do something with service
          print(service);
        });
      }
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

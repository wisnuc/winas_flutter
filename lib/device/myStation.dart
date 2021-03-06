import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import './network.dart';
import './deviceInfo.dart';
import './newDeviceName.dart';
import './firmwareUpdate.dart';

import '../login/ble.dart';
import '../redux/redux.dart';
import '../common/utils.dart';
import '../login/stationList.dart';
import '../login/scanBleDevice.dart';

class StorageDetail extends StatelessWidget {
  StorageDetail(this.usageData);
  final List usageData;
  Widget row(u) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1.0, color: Colors.grey[200]),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              color: u['color'],
            ),
            child: Icon(u['icon'], color: Colors.white),
          ),
          Container(width: 16),
          Expanded(
            flex: 1,
            child: Container(
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 10,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          u['title'],
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.fade,
                          maxLines: 1,
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        Container(height: 4),
                        Text(
                          u['count'].toString(),
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(),
                    flex: 1,
                  ),
                  Text(
                    u['size'],
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0, // no shadow
        backgroundColor: Colors.white10,
        brightness: Brightness.light,
        iconTheme: IconThemeData(color: Colors.black38),
        title: Text('存储详情', style: TextStyle(color: Colors.black87)),
      ),
      body: ListView(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: usageData
                  .where((d) => d['title'] != null)
                  .map((u) => row(u))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class MyStation extends StatefulWidget {
  MyStation({Key key}) : super(key: key);

  @override
  _MyStationState createState() => new _MyStationState();
}

class _MyStationState extends State<MyStation> {
  bool loading = true;
  String usage = '';
  List usageData = [];

  Future refresh(AppState state) async {
    var space;
    var stats;
    // request data
    try {
      List results = await Future.wait([
        state.apis.req('space', null),
        state.apis.req('stats', null),
      ]);
      space = results[0].data;
      stats = results[1].data;
    } catch (error) {
      setState(() {
        loading = false;
      });
      return null;
    }
    var total = prettySize(space['total'] * 1024);
    var used = prettySize(space['used'] * 1024);

    var usedPercent = space['used'] / (space['available'] + space['used']);
    int videoRaw = stats['video']['totalSize'];
    int imageRaw = stats['image']['totalSize'];
    int audioRaw = stats['audio']['totalSize'];
    int documentRaw = stats['document']['totalSize'];
    int othersRaw = stats['others']['totalSize'];

    int countTotal =
        ((videoRaw + imageRaw + audioRaw + documentRaw + othersRaw) /
                usedPercent /
                100)
            .round();

    countTotal = countTotal == 0 ? 1 : countTotal;

    int videoSize = videoRaw == 0 ? 0 : max(videoRaw / countTotal, 3.0).ceil();
    int imageSize = imageRaw == 0 ? 0 : max(imageRaw / countTotal, 3.0).ceil();
    int audioSize = audioRaw == 0 ? 0 : max(audioRaw / countTotal, 3.0).ceil();
    int documentSize =
        documentRaw == 0 ? 0 : max(documentRaw / countTotal, 3.0).ceil();
    int otherSize =
        othersRaw == 0 ? 0 : max(othersRaw / countTotal, 3.0).ceil();
    int restSize = max(
        100 - videoSize - imageSize - audioSize - documentSize - otherSize, 0);

    usageData = [
      {
        'color': Color(0xFF2196f3),
        'flex': videoSize,
        'title': '视频',
        'size': prettySize(videoRaw),
        'icon': Icons.folder,
        'count': stats['video']['count'],
      },
      {
        'color': Color(0xFFaa00ff),
        'flex': imageSize,
        'title': '图片',
        'size': prettySize(imageRaw),
        'icon': Icons.image,
        'count': stats['image']['count'],
      },
      {
        'color': Color(0xFFf2497d),
        'flex': audioSize,
        'title': '音乐',
        'size': prettySize(audioRaw),
        'icon': Icons.music_note,
        'count': stats['audio']['count'],
      },
      {
        'color': Color(0xFFffb300),
        'flex': documentSize,
        'title': '文档',
        'size': prettySize(documentRaw),
        'icon': Icons.text_fields,
        'count': stats['document']['count'],
      },
      {
        'color': Color(0xFF00c853),
        'flex': otherSize,
        'title': '其他',
        'size': prettySize(othersRaw),
        'icon': Icons.insert_drive_file,
        'count': stats['others']['count'],
      },
      {
        'color': Colors.grey[200],
        'flex': restSize,
      },
    ];
    usage = '已使用$used/$total';

    if (this.mounted) {
      // avoid calling setState after dispose()
      setState(() {
        loading = false;
      });
    }
    return null;
  }

  List<Widget> _actions(AppState state) {
    return [
      // add device
      Builder(
        builder: (ctx) => IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return ScanBleDevice(
                        request: state.cloud,
                        action: Action.bind,
                      );
                    },
                  ),
                );
              },
            ),
      ),
      // switch device
      Builder(
        builder: (ctx) => IconButton(
              icon: Icon(Icons.swap_horiz),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) {
                      return StationList(
                        request: state.cloud,
                        stationList: null,
                        currentDevSN: state.device.deviceSN,
                      );
                    },
                  ),
                );
              },
            ),
      ),
    ];
  }

  void rename(AppState state) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) {
            return NewDeviceName(deviceName: state.device.deviceName);
          },
          fullscreenDialog: true,
        ),
      );

      await refresh(state);
    } catch (error) {
      print(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) =>
          refresh(store.state).catchError((error) => print(error)),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white10,
            brightness: Brightness.light,
            iconTheme: IconThemeData(color: Colors.black38),
            title: Text('设备', style: TextStyle(color: Colors.black87)),
            elevation: 0.0, // no shadow
            actions: _actions(state),
          ),
          body: loading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : ListView(
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Container(
                          height: 60,
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Row(
                            children: <Widget>[
                              Container(
                                constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width -
                                            108),
                                child: Text(
                                  state?.device?.deviceName ?? '',
                                  style: TextStyle(fontSize: 28),
                                  textAlign: TextAlign.start,
                                  overflow: TextOverflow.fade,
                                  softWrap: false,
                                  maxLines: 1,
                                ),
                              ),
                              // rename device
                              Builder(
                                builder: (ctx) {
                                  return IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () => rename(state),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(
                              Radius.circular(6),
                            ),
                            child: Container(
                              height: 24,
                              child: Row(
                                children: usageData
                                    .map((u) => Expanded(
                                          flex: u['flex'],
                                          child: Container(
                                            color: u['color'],
                                            margin: EdgeInsets.only(
                                              right: u == usageData.last ||
                                                      u['flex'] == 0
                                                  ? 0
                                                  : 3,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          height: 32,
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                          child: Row(
                              children: usageData
                                  .where((d) => d['title'] != null)
                                  .map((u) => Row(
                                        children: <Widget>[
                                          Container(
                                            height: 12,
                                            width: 12,
                                            decoration: BoxDecoration(
                                              color: u['color'],
                                              borderRadius: BorderRadius.all(
                                                const Radius.circular(3),
                                              ),
                                            ),
                                            margin:
                                                EdgeInsets.fromLTRB(0, 8, 8, 8),
                                          ),
                                          Text(
                                            u['title'],
                                          ),
                                          Container(width: 8),
                                        ],
                                      ))
                                  .toList()),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) {
                                      return StorageDetail(usageData);
                                    },
                                    fullscreenDialog: true,
                                  ),
                                ),
                            child: Container(
                              height: 64,
                              padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
                              child: Row(
                                children: <Widget>[
                                  Text(
                                    usage,
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black54),
                                  ),
                                  Expanded(flex: 1, child: Container()),
                                  Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ),
                        ),
                        actionButton(
                          '设备网络',
                          () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return Network();
                                }),
                              ),
                          null,
                        ),
                        actionButton(
                          '关于本机',
                          () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return DeviceInfo();
                                }),
                              ),
                          null,
                        ),
                        actionButton(
                          '软件更新',
                          () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return Firmware();
                                }),
                              ),
                          null,
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

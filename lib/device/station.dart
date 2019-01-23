import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import '../redux/redux.dart';
import '../common/format.dart';
import './backup.dart';
import './network.dart';
import './advanced_settings.dart';

class Station extends StatefulWidget {
  Station({Key key}) : super(key: key);

  @override
  _StationState createState() => new _StationState();
}

class _StationState extends State<Station> {
  bool loading = true;
  String usage = '';
  String deviceName = '';
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
      deviceName = state.device.deviceName;
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

    int videoSize = max(videoRaw / countTotal, 3.0).ceil();
    int imageSize = max(imageRaw / countTotal, 3.0).ceil();
    int audioSize = max(audioRaw / countTotal, 3.0).ceil();
    int documentSize = max(documentRaw / countTotal, 3.0).ceil();
    int otherSize = max(othersRaw / countTotal, 3.0).ceil();
    int restSize = max(
        100 - videoSize - imageSize - audioSize - documentSize - otherSize, 0);

    usageData = [
      {
        'color': Color(0xFF2196f3),
        'flex': videoSize,
        'title': '视频',
        'size': prettySize(videoRaw)
      },
      {
        'color': Color(0xFFaa00ff),
        'flex': imageSize,
        'title': '图片',
        'size': prettySize(imageSize)
      },
      {
        'color': Color(0xFFf2497d),
        'flex': audioSize,
        'title': '音乐',
        'size': prettySize(audioSize)
      },
      {
        'color': Color(0xFFffb300),
        'flex': documentSize,
        'title': '文档',
        'size': prettySize(documentSize)
      },
      {
        'color': Color(0xFF00c853),
        'flex': otherSize,
        'title': '其他',
        'size': prettySize(otherSize)
      },
      {
        'color': Colors.grey[200],
        'flex': restSize,
      },
    ];
    usage = '已使用$used/$total';

    if (this.mounted) {
      // avoid calling setState after dispose()
      setState(() {});
    }
    return null;
  }

  void refreshAsync(state) {
    refresh(state).then((data) {
      setState(() {
        loading = false;
      });
      print('refresh success');
    }).catchError((error) {
      setState(() {
        loading = false;
      });
      print(error); // TODO
    });
  }

  List<Widget> _actions = [
    IconButton(
      icon: Icon(Icons.add),
      onPressed: () => {},
    ),
    IconButton(
      icon: Icon(Icons.edit),
      onPressed: () => {},
    ),
    IconButton(
      icon: Icon(Icons.swap_horiz),
      onPressed: () => {},
    ),
  ];

  Widget actionItem(String title, Function action) {
    return Container(
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action,
          child: Row(
            children: <Widget>[
              Text(
                title,
                style: TextStyle(fontSize: 16),
              ),
              Expanded(
                flex: 1,
                child: Container(),
              ),
              Icon(Icons.keyboard_arrow_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget divider() {
    return Container(
      width: double.infinity,
      height: 1,
      color: Color(0x08000000),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => refreshAsync(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white10,
            iconTheme: IconThemeData(color: Colors.black38),
            title: Text('设备', style: TextStyle(color: Colors.black87)),
            elevation: 0.0, // no shadow
            actions: _actions,
          ),
          body: loading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Container(
                  constraints: BoxConstraints.expand(),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 60,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Expanded(
                              flex: 10,
                              child: Text(
                                deviceName,
                                style: TextStyle(fontSize: 28),
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Expanded(
                              child: Container(),
                              flex: 1,
                            ),
                            Text(
                              usage,
                              style: TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                      ClipRRect(
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
                                          margin:
                                              EdgeInsets.fromLTRB(0, 0, 3, 0),
                                        ),
                                      ))
                                  .toList()),
                        ),
                      ),
                      Container(
                        height: 32,
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
                      actionItem(
                        '备份',
                        () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return Backup();
                              }),
                            ),
                      ),
                      divider(),
                      actionItem(
                        '网络',
                        () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return NetWork();
                              }),
                            ),
                      ),
                      divider(),
                      actionItem(
                        '高级',
                        () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return AdvancedSettings();
                              }),
                            ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

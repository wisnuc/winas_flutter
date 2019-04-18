import 'package:redux/redux.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import './file.dart';
import '../redux/redux.dart';
import '../icons/winas_icons.dart';

class BackupView extends StatefulWidget {
  BackupView({Key key}) : super(key: key);

  @override
  _BackupViewState createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  ScrollController myScrollController = ScrollController();
  List<Drive> drives = [];

  bool loading = true;

  String error;

  Future updateDirSize(AppState state, Drive drive) async {
    var res = await state.apis
        .req('dirStat', {'driveUUID': drive.uuid, 'dirUUID': drive.uuid});
    drive.updateStats(res.data);
  }

  Future refresh(store) async {
    try {
      if (mounted && loading == false) {
        setState(() {
          loading = true;
        });
      }
      AppState state = store.state;
      // get current drives data
      final res = await state.apis.req('drives', null);
      List<Drive> allDrives = List.from(
        res.data.map((drive) => Drive.fromMap(drive)),
      );

      store.dispatch(
        UpdateDrivesAction(allDrives),
      );

      drives = List.from(
        allDrives.where((drive) => drive.type == 'backup'),
      );
      List<Future> reqs = [];
      for (Drive drive in drives) {
        reqs.add(updateDirSize(state, drive));
      }
      await Future.wait(reqs);
      if (mounted) {
        setState(() {
          loading = false;
          error = null;
        });
      }
    } catch (e) {
      print(e);
      if (mounted) {
        setState(() {
          error = 'refresh failed';
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Store<AppState>>(
      onInit: (store) => refresh(store),
      onDispose: (store) => {},
      converter: (store) => store,
      builder: (context, store) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0.0, // no shadow
            brightness: Brightness.light,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black38),
            title: Text('备份空间', style: TextStyle(color: Colors.black87)),
          ),
          body: loading
              ? Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(
                      child: Column(
                        children: <Widget>[
                          Expanded(flex: 4, child: Container()),
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Container(
                              width: 72,
                              height: 72,
                              // padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(36),
                              ),
                              child: Icon(
                                Winas.logo,
                                color: Colors.grey[50],
                                size: 84,
                              ),
                            ),
                          ),
                          Text(
                            '加载页面失败，请检查网络设置',
                            style: TextStyle(color: Colors.black38),
                          ),
                          FlatButton(
                            padding: EdgeInsets.all(0),
                            child: Text(
                              '重新加载',
                              style: TextStyle(color: Colors.teal),
                            ),
                            onPressed: () => refresh(store),
                          ),
                          Expanded(flex: 6, child: Container()),
                        ],
                      ),
                    )
                  : drives.length == 0
                      ? Column(
                          children: <Widget>[
                            Expanded(flex: 1, child: Container()),
                            Icon(
                              Icons.content_copy,
                              color: Colors.grey[300],
                              size: 84,
                            ),
                            Container(height: 16),
                            Text('您尚未创建备份文件'),
                            Expanded(
                              flex: 2,
                              child: Container(),
                            ),
                          ],
                        )
                      : CustomScrollView(
                          controller: myScrollController,
                          physics: AlwaysScrollableScrollPhysics(),
                          slivers: <Widget>[
                            SliverFixedExtentList(
                              itemExtent: 48.0,
                              delegate: SliverChildBuilderDelegate(
                                  (context, index) => Column(
                                        children: <Widget>[
                                          Container(
                                              height: 8,
                                              color: Colors.grey[100]),
                                          Container(
                                            padding: EdgeInsets.only(
                                                left: 18, right: 18),
                                            height: 40,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: <Widget>[
                                                Text(
                                                  '备份设备',
                                                  style: TextStyle(
                                                      color: Colors.black54),
                                                ),
                                                Text(
                                                  '已备容量',
                                                  style: TextStyle(
                                                      color: Colors.black54),
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                  childCount: 1),
                            ),
                            SliverFixedExtentList(
                              itemExtent: 64.0,
                              delegate:
                                  SliverChildBuilderDelegate((context, index) {
                                Drive drive = drives[index];
                                print('drive $drive');
                                bool isMobile = [
                                  'Mobile-iOS',
                                  'Mobile-Android',
                                ].contains(drive?.client?.type);
                                return Material(
                                  child: InkWell(
                                    onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) {
                                              return Files(
                                                node: Node(
                                                  name: drive.label,
                                                  driveUUID: drive.uuid,
                                                  dirUUID: drive.uuid,
                                                  tag: 'dir',
                                                  location: 'backup',
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                    child: Container(
                                      constraints: BoxConstraints.expand(),
                                      padding:
                                          EdgeInsets.fromLTRB(16, 12, 16, 12),
                                      child: Row(
                                        children: <Widget>[
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              // color: Colors.cyan[800],
                                              color: isMobile
                                                  ? Colors.black
                                                  : Colors.blue,
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(20),
                                              ),
                                            ),
                                            child: Icon(
                                              isMobile
                                                  ? Icons.phone_iphone
                                                  : Icons.laptop,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Container(width: 16),
                                          Text(
                                            drive.label,
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          Expanded(flex: 1, child: Container()),
                                          Text(
                                            drive.fileTotalSize == '0 B'
                                                ? '未备份'
                                                : drive.fileTotalSize,
                                            style: TextStyle(
                                                color: Colors.black54),
                                          ),
                                          Icon(Icons.chevron_right),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }, childCount: drives.length),
                            ),
                          ],
                        ),
        );
      },
    );
  }
}

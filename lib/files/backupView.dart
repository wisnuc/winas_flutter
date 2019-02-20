import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:draggable_scrollbar/draggable_scrollbar.dart';
import '../redux/redux.dart';
import './file.dart';

class BackupView extends StatefulWidget {
  BackupView({Key key}) : super(key: key);

  @override
  _BackupViewState createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  ScrollController myScrollController = ScrollController();
  List<Drive> drives = [];

  Future updateDirSize(AppState state, Drive drive) async {
    var res = await state.apis
        .req('dirStat', {'driveUUID': drive.uuid, 'dirUUID': drive.uuid});
    drive.updateStats(res.data);
  }

  Future refresh(AppState state) async {
    drives = List.from(
      state.drives.where((drive) => drive.type == 'backup'),
    );
    List<Future> reqs = [];
    for (Drive drive in drives) {
      reqs.add(updateDirSize(state, drive));
    }
    await Future.wait(reqs);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => refresh(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0.0, // no shadow
            backgroundColor: Colors.white10,
            iconTheme: IconThemeData(color: Colors.black38),
            title: Text('备份空间', style: TextStyle(color: Colors.black87)),
          ),
          body: DraggableScrollbar.semicircle(
            controller: myScrollController,
            child: CustomScrollView(
              controller: myScrollController,
              physics: AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverFixedExtentList(
                  itemExtent: 48.0,
                  delegate: SliverChildBuilderDelegate(
                      (context, index) => Column(
                            children: <Widget>[
                              Container(height: 8, color: Colors.grey[100]),
                              Container(
                                padding: EdgeInsets.only(left: 18, right: 18),
                                height: 40,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Text(
                                      '备份设备',
                                      style: TextStyle(color: Colors.black54),
                                    ),
                                    Text(
                                      '已备容量',
                                      style: TextStyle(color: Colors.black54),
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
                  delegate: SliverChildBuilderDelegate((context, index) {
                    Drive drive = drives[index];
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
                          padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  // color: Colors.cyan[800],
                                  color: Colors.indigo[800],
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20),
                                  ),
                                ),
                                child: Icon(
                                  // Icons.phone_iphone,
                                  Icons.laptop,
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
                                drive.fileTotalSize,
                                style: TextStyle(color: Colors.black54),
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
          ),
        );
      },
    );
  }
}

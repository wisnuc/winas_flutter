import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import '../redux/redux.dart';
import '../common/utils.dart';
import '../common/renderIcon.dart';

class DetailRows {
  String type;
  String location;
  String size;
  String date;
  String fileCount;
  String dirCount;
  String namepath;
  DetailRows(
      {this.type,
      this.location,
      this.size,
      this.date,
      this.dirCount,
      this.namepath,
      this.fileCount});
  update({String size, String fileCount, String dirCount, String namepath}) {
    this.size = size ?? this.size;
    this.fileCount = fileCount ?? this.fileCount;
    this.dirCount = dirCount ?? this.dirCount;
    this.namepath = namepath ?? this.namepath;
  }

  List toList() {
    List list = [
      ['类型', type],
      ['大小', size],
      ['位置', namepath],
    ];
    if (fileCount != null) list.add(['子文件数目', this.fileCount]);
    if (dirCount != null) list.add(['子文件夹数目', this.dirCount]);
    list.add(['修改日期', this.date]);
    return list;
  }
}

class Detail extends StatefulWidget {
  Detail(this.entry, {Key key}) : super(key: key);
  final Entry entry;
  @override
  _DetailState createState() => _DetailState(entry);
}

class _DetailState extends State<Detail> {
  final Entry entry;
  DetailRows rows;
  _DetailState(this.entry);

  /// 1. getFolderSize
  /// 2. get namePath
  init(AppState state) async {
    getNamePath(state).catchError(print);
    getFolderSize(state).catchError(print);
  }

  String transformLocation(loc) {
    switch (loc) {
      case 'home':
        return '我的空间';
      case 'built-in':
        return '共享空间';
      case 'backup':
        return '备份空间';
    }
    return '';
  }

  Future getNamePath(AppState state) async {
    print("entry $entry");
    try {
      // request entries/path
      final res = await state.apis
          .req('listNavDir', {'driveUUID': entry.pdrv, 'dirUUID': entry.pdir});

      // root
      List<String> paths = [transformLocation(entry.location)];

      Drive drive = state.drives.firstWhere((d) => d.uuid == entry.pdrv);
      if (drive.type == 'backup') {
        paths.add(drive.label);
      }

      // skip first item
      final rest = (res.data['path'] as List).map((p) => p['name']).skip(1);

      paths.addAll(List.from(rest));
      rows.update(namepath: paths.join('/'));
    } catch (error) {
      print('getNamePath error: $error');
    }
    setState(() {});
  }

  Future getFolderSize(AppState state) async {
    if (entry.type != 'file') {
      try {
        final stat = await state.apis
            .req('dirStat', {'driveUUID': entry.pdrv, 'dirUUID': entry.uuid});

        // update folder's size, fileCount, dirCount
        rows.update(
            size: prettySize(stat.data['fileTotalSize']),
            fileCount: stat.data['fileCount'].toString(),
            dirCount: stat.data['dirCount'].toString());
      } catch (error) {
        print('getFolderSize error: $error');
      }
      setState(() {});
    }
  }

  @override
  void initState() {
    final loadingText = '加载中';
    rows = DetailRows(
      type: entry.type == 'file' ? entry?.metadata?.type ?? '文件' : '文件夹',
      size: entry.type == 'file' ? entry.hsize : loadingText,
      location: entry.location,
      dirCount: entry.type == 'file' ? null : loadingText,
      fileCount: entry.type == 'file' ? null : loadingText,
      namepath: loadingText,
      date: entry.hmtime,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List rowList = rows.toList();
    return StoreConnector<AppState, AppState>(
        onInit: (store) => init(store.state),
        onDispose: (store) => {},
        converter: (store) => store.state,
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0.0, // no shadow
              backgroundColor: Colors.grey[300],
              brightness: Brightness.light,
              iconTheme: IconThemeData(color: Colors.black38),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Container(
                    color: Colors.grey[300],
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: EdgeInsets.fromLTRB(16, 24, 16, 24),
                          child: entry.type == 'file'
                              ? renderIcon(entry.name, entry.metadata,
                                  size: 24.0)
                              : Icon(Icons.folder,
                                  color: Colors.orange, size: 24.0),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            entry.name,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Container(width: 8),
                      ],
                    ),
                  ),
                  Container(height: 16),
                  Column(
                    children: rowList
                        .map(
                          (row) => Container(
                                // height: 48,
                                padding: EdgeInsets.fromLTRB(0, 12, 16, 12),
                                child: Row(
                                  children: <Widget>[
                                    Container(width: 56),
                                    Expanded(
                                      flex: 2,
                                      child: Text(row[0]),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Container(
                                        padding: EdgeInsets.only(left: 24),
                                        child: Text(
                                          row[1],
                                          softWrap: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        )
                        .toList(),
                  )
                ],
              ),
            ),
          );
        });
  }
}

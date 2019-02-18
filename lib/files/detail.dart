import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/material.dart';
import '../common/format.dart';
import '../redux/redux.dart';
import '../common/renderIcon.dart';

class DetailRows {
  String type;
  String location;
  String size;
  String date;
  String fileCount;
  String dirCount;
  DetailRows(
      {this.type,
      this.location,
      this.size,
      this.date,
      this.dirCount,
      this.fileCount});
  update({String size, String fileCount, String dirCount}) {
    this.size = size ?? this.size;
    this.fileCount = fileCount ?? this.fileCount;
    this.dirCount = dirCount ?? this.dirCount;
  }

  List toList() {
    List list = [
      ['类型', type],
      ['大小', size]
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

  getFolderSize(AppState state) async {
    if (entry.type != 'file') {
      var stat;
      try {
        stat = await state.apis
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
    rows = DetailRows(
      type: entry.type == 'file' ? entry?.metadata?.type ?? '文件' : '文件夹',
      size: entry.type == 'file' ? entry.hsize : '加载中',
      dirCount: entry.type == 'file' ? null : '加载中',
      fileCount: entry.type == 'file' ? null : '加载中',
      date: entry.hmtime,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List rowList = rows.toList();
    return StoreConnector<AppState, AppState>(
        onInit: (store) => getFolderSize(store.state),
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
            body: Column(
              children: <Widget>[
                Container(
                  color: Colors.grey[300],
                  child: Row(
                    children: <Widget>[
                      Container(
                        height: 72,
                        padding: EdgeInsets.all(16),
                        child: entry.type == 'file'
                            ? renderIcon(entry.name, entry.metadata, size: 24.0)
                            : Icon(Icons.folder,
                                color: Colors.orange, size: 24.0),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          entry.name,
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.start,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
                              height: 48,
                              child: Row(
                                children: <Widget>[
                                  Container(width: 56),
                                  Expanded(
                                    flex: 2,
                                    child: Text(row[0]),
                                  ),
                                  Expanded(
                                    flex: 5,
                                    child: Container(
                                      padding: EdgeInsets.only(left: 24),
                                      width: 256,
                                      child: Text(row[1]),
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
          );
        });
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import './photo.dart';
import './detail.dart';
import '../redux/redux.dart';
import '../common/renderIcon.dart';
import '../common/taskManager.dart';

class FileNavView {
  final Widget _icon;
  final String _title;
  final String _nav;
  final Color _color;
  final Function _onTap;

  FileNavView({
    Widget icon,
    String title,
    String nav,
    Color color,
    Function onTap,
    TickerProvider vsync,
  })  : _icon = icon,
        _title = title,
        _nav = nav,
        _color = color,
        _onTap = onTap;

  Widget navButton(context) {
    return Container(
      width: 71,
      height: 79,
      margin: EdgeInsets.fromLTRB(8, 12, 8, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTap(context),
          onLongPress: () => print('long press: $_nav'),
          child: Column(
            children: <Widget>[
              Container(
                height: 48,
                width: 48,
                child: _icon,
                decoration: BoxDecoration(
                  color: _color,
                  borderRadius: BorderRadius.all(
                    const Radius.circular(24),
                  ),
                ),
              ),
              Container(
                height: 31,
                width: 71,
                child: Center(
                  child: Text(
                    _title,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TitleRow extends StatelessWidget {
  TitleRow({
    @required this.type, // directory or file
    @required this.isFirst,
    this.entrySort,
  });

  final type;
  final isFirst;
  final EntrySort entrySort;

  @override
  Widget build(BuildContext context) {
    if (!isFirst)
      return Container(
        height: 48,
        padding: EdgeInsets.fromLTRB(16, 0, 0, 0),
        alignment: Alignment.centerLeft,
        child: type == 'file' ? Text('文件') : Text('文件夹'),
      );

    return Container(
      height: 48,
      child: Row(
        children: <Widget>[
          Container(width: 16),
          Container(
            child: type == 'file' ? Text('文件') : Text('文件夹'),
          ),
          Expanded(
            flex: 1,
            child: Container(),
          ),
          entrySort == null
              ? Container(
                  child: Text(
                    '名称',
                    style: TextStyle(color: Colors.black38, fontSize: 14),
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton(
                    onChanged: (value) {
                      entrySort.changeType(value);
                    },
                    value: entrySort.type,
                    items: SortTypes.values
                        .map(
                          (type) => DropdownMenuItem(
                              value: type,
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    type.toString().endsWith('Up')
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: Colors.black26,
                                  ),
                                  Container(width: 8),
                                  Container(
                                    child: Text(
                                      entrySort.getName(type),
                                      style: TextStyle(
                                          color: Colors.black38, fontSize: 14),
                                    ),
                                  ),
                                ],
                              )),
                        )
                        .toList(),
                  ),
                ),
          Container(width: 16),
        ],
      ),
    );
  }
}

class FileRow extends StatefulWidget {
  FileRow(
      {Key key,
      this.entry,
      this.type,
      this.actions,
      this.onPress,
      this.onLongPress,
      this.select,
      this.isGrid})
      : super(key: key);
  final Entry entry;
  final String type;
  final List actions;
  final Function onPress;
  final Function onLongPress;
  final Select select;
  final bool isGrid;

  @override
  _FileRowState createState() => _FileRowState(
        entry: entry,
        type: type,
        actions: actions,
        onPress: onPress,
        onLongPress: onLongPress,
        isGrid: isGrid,
        select: select,
      );
}

class _FileRowState extends State<FileRow> {
  _FileRowState(
      {Entry entry,
      String type,
      List actions,
      Function onPress,
      Function onLongPress,
      bool isGrid,
      Select select})
      : name = entry.name,
        type = type,
        onPress = onPress,
        onLongPress = onLongPress,
        isGrid = isGrid,
        mtime = entry.hmtime,
        size = entry.hsize,
        entry = entry,
        metadata = entry.metadata,
        actions = actions,
        select = select;

  final String name;
  final String type;
  final String size;
  final String mtime;
  final Entry entry;
  final Function onPress;
  final Function onLongPress;
  final Metadata metadata;
  final List actions;
  final bool isGrid;
  final Select select;
  ThumbTask task;

  String _thumbSrc;

  _getThumb(AppState state) {
    // check hash
    if (entry.hash == null) return;
    final tm = TaskManager.getInstance();
    task = tm.createThumbTask(entry, state, (error, value) {
      if (!error && value is String && this.mounted) {
        setState(() {
          _thumbSrc = value;
        });
      }
    });
  }

  _onPressMore(BuildContext ctx) {
    if (!select.selectMode()) {
      showModalBottomSheet(
        context: ctx,
        builder: (BuildContext c) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(width: 24),
                    type == 'file'
                        ? renderIcon(name, metadata)
                        : Icon(Icons.folder, color: Colors.orange),
                    Container(width: 32),
                    Expanded(
                      child: Text(
                        name,
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      flex: 10,
                    ),
                    Expanded(
                      child: Container(),
                      flex: 1,
                    ),
                    IconButton(
                      icon: Icon(Icons.info),
                      onPressed: () {
                        Navigator.pop(c);
                        Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (xcopyCtx) {
                              return Detail(entry);
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.grey[300],
                ),
                Container(height: 8),
                Column(
                  children: actions
                      .where((action) => action['types'].contains(type))
                      .map<Widget>((value) => actionItem(
                            ctx,
                            value['icon'],
                            value['title'],
                            value['action'],
                          ))
                      .toList(),
                )
              ],
            ),
          );
        },
      );
    }
  }

  _onTap(BuildContext ctx) {
    if (select.selectMode()) {
      select.toggleSelect(entry);
    } else if (photoMagic.indexOf(entry?.metadata?.type) > -1) {
      showPhoto(ctx, entry, _thumbSrc);
    } else {
      onPress();
    }
  }

  Widget actionItem(
      BuildContext ctx, IconData icon, String title, Function action) {
    return Material(
      child: InkWell(
        onTap: () => action(ctx, entry),
        child: Container(
          padding: EdgeInsets.all(8),
          child: Row(
            children: <Widget>[
              Container(width: 16),
              Icon(icon),
              Container(width: 32),
              Text(
                title,
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget renderRowInGrid(BuildContext ctx) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 4,
        ),
        Container(
          height: 40,
          width: 40,
          child: (entry.selected && type != 'file')
              ? Icon(Icons.check, color: Colors.white)
              : type == 'file'
                  ? renderIcon(name, metadata)
                  : Icon(Icons.folder, color: Colors.orange),
          decoration: BoxDecoration(
            color: (select.selectMode() && type != 'file')
                ? entry.selected ? Colors.teal : Colors.black12
                : Colors.transparent,
            borderRadius: BorderRadius.all(
              const Radius.circular(20),
            ),
          ),
        ),
        Container(width: 4),
        Expanded(
          child: Text(
            name,
            textAlign: TextAlign.start,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          flex: 10,
        ),
        Expanded(
          child: Container(),
          flex: 1,
        ),
        IconButton(
          icon: Icon(Icons.more_horiz),
          onPressed: () => _onPressMore(ctx),
        ),
      ],
    );
  }

  Widget renderGrid(BuildContext ctx, String thumbSrc) {
    return type == 'file'
        ? Column(
            children: [
              Expanded(
                flex: 1,
                child: thumbSrc == null
                    ? renderIcon(entry.name, entry.metadata, size: 72.0)
                    // show thumb
                    : Hero(
                        tag: entry.uuid,
                        child: Image.file(
                          File(thumbSrc),
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
              renderRowInGrid(ctx),
            ],
          )
        : renderRowInGrid(ctx);
  }

  Widget renderRow(BuildContext ctx) {
    return Row(
      children: <Widget>[
        Container(width: 12),
        Container(
          height: 48,
          width: 48,
          child: entry.selected
              ? Icon(Icons.check, color: Colors.white)
              : type == 'file'
                  ? renderIcon(name, metadata)
                  : Icon(Icons.folder, color: Colors.orange),
          decoration: BoxDecoration(
            color: select.selectMode()
                ? entry.selected ? Colors.teal : Colors.black12
                : Colors.transparent,
            borderRadius: BorderRadius.all(
              const Radius.circular(24),
            ),
          ),
        ),
        Container(width: 20),
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 1.0, color: Colors.grey[300]),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 10,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        name,
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Container(height: 4),
                      Row(
                        children: <Widget>[
                          Text(
                            mtime,
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                          Container(width: 8),
                          size != null && type == 'file'
                              ? Text(
                                  size,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                )
                              : Container(),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(),
                  flex: 1,
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz),
                  onPressed: () => _onPressMore(ctx),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    task?.abort();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => _getThumb(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (ctx, state) {
        return Container(
          child: Material(
            child: InkWell(
              onTap: () => _onTap(context),
              onLongPress: () {
                if (!select.selectMode()) {
                  select.toggleSelect(entry);
                }
              },
              child: isGrid
                  ? Stack(
                      children: <Widget>[
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: renderGrid(context, _thumbSrc),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: (select.selectMode() && entry.type == 'file')
                              ? Container(
                                  color: Colors.black12,
                                  child: Center(
                                    child: Container(
                                      height: 48,
                                      width: 48,
                                      child: entry.selected
                                          ? Icon(Icons.check,
                                              color: Colors.white)
                                          : Container(),
                                      decoration: BoxDecoration(
                                        color: entry.selected
                                            ? Colors.teal
                                            : Colors.black12,
                                        borderRadius: BorderRadius.all(
                                          const Radius.circular(24),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Container(),
                        )
                      ],
                    )
                  : renderRow(context),
            ),
          ),
        );
      },
    );
  }
}

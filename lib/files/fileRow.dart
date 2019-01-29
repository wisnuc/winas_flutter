import 'package:flutter/material.dart';
import '../redux/redux.dart';
import '../common/renderIcon.dart';

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
  });

  final type;
  final isFirst;

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
          Container(
            child: Text(
              '名称',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          Container(width: 16),
        ],
      ),
    );
  }
}

class FileRow extends StatelessWidget {
  FileRow({
    @required this.name,
    @required this.type,
    @required this.onPress,
    this.mtime,
    this.size,
    this.entry,
    this.actions,
    this.metadata,
  });

  final name;
  final type;
  final size;
  final mtime;
  final Entry entry;
  final Function onPress;
  final Metadata metadata;
  final List actions;

  Widget actionItem(
      BuildContext ctx, IconData icon, String title, Function action) {
    return Container(
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => action(ctx, entry),
          child: Row(
            children: <Widget>[
              Container(width: 24),
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

  _onPress(ctx) {
    print('context in FileRow._onPress: $ctx');
    showModalBottomSheet(
      context: ctx,
      builder: (BuildContext context) {
        return Container(
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
                  Text(
                    name,
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Expanded(
                    child: Container(),
                    flex: 1,
                  ),
                  IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () => print('press info'),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      child: Material(
        child: InkWell(
          onTap: onPress,
          onLongPress: () => print('long press: $name'),
          child: Row(
            children: <Widget>[
              Container(width: 24),
              type == 'file'
                  ? renderIcon(name, metadata)
                  : Icon(Icons.folder, color: Colors.orange),
              Container(width: 32),
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
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black54),
                                ),
                                Container(width: 8),
                                size != null
                                    ? Text(
                                        size,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black54),
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
                        onPressed: () => _onPress(context),
                      )
                    ],
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

class FileGrid extends StatelessWidget {
  FileGrid({
    @required this.name,
    @required this.type,
    @required this.onPress,
    this.mtime,
    this.size,
    this.entry,
    this.actions,
    this.metadata,
  });

  final name;
  final type;
  final size;
  final mtime;
  final Entry entry;
  final Function onPress;
  final Metadata metadata;
  final List actions;

  Widget actionItem(
      BuildContext ctx, IconData icon, String title, Function action) {
    return Container(
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => action(ctx, entry),
          child: Row(
            children: <Widget>[
              Container(width: 24),
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

  _onPress(ctx) {
    print('context in FileRow._onPress: $ctx');
    showModalBottomSheet(
      context: ctx,
      builder: (BuildContext context) {
        return Container(
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
                  Text(
                    name,
                    textAlign: TextAlign.start,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Expanded(
                    child: Container(),
                    flex: 1,
                  ),
                  IconButton(
                    icon: Icon(Icons.info),
                    onPressed: () => print('press info'),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      child: Material(
        child: InkWell(
          onTap: onPress,
          onLongPress: () => print('long press: $name'),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              type == 'file'
                  ? Expanded(
                      flex: 1,
                      child: renderIcon(name, metadata, size: 72.0),
                    )
                  : Container(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(width: 16),
                  type == 'file'
                      ? renderIcon(name, metadata)
                      : Icon(Icons.folder, color: Colors.orange),
                  Container(width: 16),
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
                    onPressed: () => _onPress(context),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

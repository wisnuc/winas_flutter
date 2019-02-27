import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import './license.dart';
import '../icons/winas_icons.dart';

class Detail extends StatefulWidget {
  Detail({Key key}) : super(key: key);
  @override
  _DetailState createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  @override
  void initState() {
    super.initState();
  }

  Widget actionItem(String title, Function action, Widget rightItem) {
    return Container(
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(width: 1.0, color: Colors.grey[200]),
              ),
            ),
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
                rightItem ?? Icon(Icons.keyboard_arrow_right),
              ],
            ),
          ),
        ),
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
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('个人中心', style: TextStyle(color: Colors.black87, fontSize: 21)),
            Container(height: 16),
            actionItem(
              '语言',
              () => {},
              Text('中文'),
            ),
            actionItem(
              '语言',
              () => {},
              Text('中文'),
            ),
            actionItem(
              '语言',
              () => {},
              Text('中文'),
            ),
            actionItem(
              '语言',
              () => {},
              Text('中文'),
            ),
          ],
        ),
      ),
    );
  }
}

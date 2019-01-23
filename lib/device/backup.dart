import 'package:flutter/material.dart';

class Backup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0, // no shadow
        backgroundColor: Colors.white10,
        iconTheme: IconThemeData(color: Colors.black38),
        title: Text('备份', style: TextStyle(color: Colors.black87)),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints.expand(),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[],
          ),
        ),
      ),
    );
  }
}

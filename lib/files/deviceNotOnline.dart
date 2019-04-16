import 'package:flutter/material.dart';

import '../common/utils.dart';

class DeviceNotOnline extends StatelessWidget {
  DeviceNotOnline({Key key}) : super(key: key);
  final Model model = Model();
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => Future.value(model.shouldClose),
      child: AlertDialog(
        title: Text('设备已离线'),
        content: Text('请确认设备联网状态后，重新登录设备。'),
        actions: <Widget>[
          FlatButton(
            textColor: Theme.of(context).primaryColor,
            child: Text('确定'),
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/deviceList', (Route<dynamic> route) => false);
            },
          )
        ],
      ),
    );
  }
}

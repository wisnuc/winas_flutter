import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux/redux.dart';
import '../common/utils.dart';

const tips = """该操作不可逆，请谨慎操作。

重置设备需要手机与设备连至同一Wi-Fi网络。

该操作将解除绑定用户，清除所有数据，恢复出厂设置。""";

enum Status {
  auth,
  authFailed,
  reseting,
  resetFailed,
  success,
}

class ResetDevice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
        onInit: (store) => {},
        onDispose: (store) => {},
        converter: (store) => store.state,
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0.0, // no shadow
              backgroundColor: Colors.white10,
              brightness: Brightness.light,
              iconTheme: IconThemeData(color: Colors.black38),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '重置设备',
                    style: TextStyle(color: Colors.black87, fontSize: 21),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
                  child: Text(
                    tips,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                Builder(builder: (ctx) {
                  return Container(
                    height: 88,
                    padding: EdgeInsets.all(16),
                    width: double.infinity,
                    child: RaisedButton(
                      color: Colors.redAccent,
                      elevation: 1.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(48),
                      ),
                      onPressed: () async {
                        showLoading(ctx);
                        final isLAN = await state.apis.testLAN();
                        if (isLAN) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => _ResetDevice()),
                          );
                        } else {
                          Navigator.pop(ctx);
                          showSnackBar(ctx, '操作失败手机与设备未连至同一Wi-Fi网络');
                        }
                      },
                      child: Row(
                        children: <Widget>[
                          Expanded(child: Container()),
                          Text(
                            '重置设备',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          Expanded(child: Container()),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        });
  }
}

class _ResetDevice extends StatefulWidget {
  _ResetDevice({Key key}) : super(key: key);

  @override
  _ResetDeviceState createState() => _ResetDeviceState();
}

class _ResetDeviceState extends State<_ResetDevice> {
  String selected;

  Status status = Status.auth;

  /// check color code
  // Future<String> checkCode(AppState state, String code) async {
  //   final args = {"action": "auth", "code": code};
  //   final res = await state.apis.req('deviceAuth', args);
  //   String token = res['data']['token'];
  //   print(token);
  //   return token;
  // }

  /// start to bind device
  Future<void> restDevice(BuildContext ctx, AppState state) async {
    setState(() {
      status = Status.reseting;
    });

    try {
      final res = await state.cloud.req('encrypted', null);
      final encrypted = res.data['encrypted'] as String;
      final resetRes =
          await state.cloud.unbindDevice(state.apis.lanIp, encrypted);
      print('resetRes: $resetRes');
      setState(() {
        status = Status.success;
      });
    } catch (e) {
      print('resetRes error $e');
      setState(() {
        status = Status.resetFailed;
      });
      return;
    }
  }

  void nextStep(BuildContext ctx, AppState state) async {
    if (status == Status.auth) {
      print('code is $selected');
      showLoading(ctx);
      try {
        await Future.delayed(Duration(seconds: 2));
        Navigator.pop(ctx);

        restDevice(ctx, state).catchError(print);
      } catch (e) {
        print(e);
        Navigator.pop(ctx);
        setState(() {
          status = Status.authFailed;
        });
      }
    }
  }

  Widget renderAuth() {
    List<String> colorCodes = [
      '红色灯 常亮',
      '绿色灯 常亮',
      '蓝色灯 常亮',
      '红色灯 闪烁',
      '绿色灯 闪烁',
      '蓝色灯 闪烁',
    ];
    List<Widget> widgets = [
      Container(
        padding: EdgeInsets.all(16),
        child: Text(
          '身份确认',
          style: TextStyle(color: Colors.black87, fontSize: 28),
        ),
      ),
      Container(
        padding: EdgeInsets.all(16),
        child: Text(
          '请您观察设备指示灯，并选择它的状态：',
          style: TextStyle(color: Colors.black54),
        ),
      ),
    ];
    print('selected: $selected');
    List<Widget> options = List.from(
      colorCodes.map(
        (code) => Material(
              child: InkWell(
                child: Container(
                  height: 56,
                  width: double.infinity,
                  child: RadioListTile(
                    activeColor: Colors.teal,
                    groupValue: selected,
                    onChanged: (value) {
                      print('on tap $code');
                      setState(() {
                        selected = value;
                      });
                    },
                    value: code,
                    title: Text(code, maxLines: 1),
                  ),
                ),
              ),
            ),
      ),
    );
    widgets.addAll(options);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget renderFailed(BuildContext ctx) {
    return Column(
      children: <Widget>[
        Container(height: 64),
        Icon(Icons.error_outline, color: Colors.redAccent, size: 96),
        Container(
          padding: EdgeInsets.all(64),
          child: Center(
            child: Text('验证失败，请重启设备后再重试'),
          ),
        ),
        Container(
          height: 88,
          padding: EdgeInsets.all(16),
          width: double.infinity,
          child: RaisedButton(
            color: Colors.teal,
            elevation: 1.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(48),
            ),
            onPressed: () {
              // return to list
              Navigator.pop(ctx);
            },
            child: Row(
              children: <Widget>[
                Expanded(child: Container()),
                Text(
                  '返回',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                Expanded(child: Container()),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget renderUnbind(BuildContext ctx) {
    String text = '';
    String buttonLabel;
    Widget icon = CircularProgressIndicator();
    switch (status) {
      case Status.reseting:
        text = '重置中';
        break;

      case Status.success:
        text = '重置成功';
        buttonLabel = '返回';
        icon = Icon(Icons.check, color: Colors.teal, size: 96);
        break;

      case Status.resetFailed:
        text = '重置失败';
        buttonLabel = '返回';
        icon = Icon(Icons.error_outline, color: Colors.redAccent, size: 96);
        break;

      default:
        text = '';
        buttonLabel = null;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(16),
          child: Text(
            '重置设备',
            style: TextStyle(color: Colors.black87, fontSize: 28),
          ),
        ),
        Container(
          height: 108,
          child: Center(child: icon),
        ),
        Container(
          height: 64,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Center(
              child: Text(
            text,
            style: TextStyle(fontSize: 18),
          )),
        ),
        buttonLabel != null
            ? Container(
                height: 88,
                padding: EdgeInsets.all(16),
                width: double.infinity,
                child: RaisedButton(
                  color: Colors.teal,
                  elevation: 1.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(48),
                  ),
                  onPressed: () {
                    if (status == Status.success) {
                      Navigator.pushNamedAndRemoveUntil(
                          ctx, '/deviceList', (Route<dynamic> route) => false);
                    } else {
                      Navigator.pop(ctx);
                    }
                  },
                  child: Row(
                    children: <Widget>[
                      Expanded(child: Container()),
                      Text(
                        buttonLabel,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      Expanded(child: Container()),
                    ],
                  ),
                ),
              )
            : Container(),
      ],
    );
  }

  Widget renderBody(BuildContext ctx) {
    switch (status) {
      case Status.auth:
        return renderAuth();

      case Status.authFailed:
        return renderFailed(ctx);

      default:
        return renderUnbind(ctx);
    }
  }

  @override
  Widget build(BuildContext context) {
    // whether has fab button or not
    bool hasFab = status == Status.auth;
    // whether has back button or not
    bool hasBack = status == Status.auth;
    // whether fab enable or not
    bool enabled = (status == Status.auth && selected != null);
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0, // no shadow
        backgroundColor: Colors.grey[50],
        automaticallyImplyLeading: hasBack,
        brightness: Brightness.light,
        iconTheme: IconThemeData(color: Colors.black38),
        actions: <Widget>[],
      ),
      body: Builder(builder: (ctx) => renderBody(ctx)),
      floatingActionButton: !hasFab
          ? null
          : Builder(
              builder: (ctx) {
                return StoreConnector<AppState, AppState>(
                    onInit: (store) => {},
                    onDispose: (store) => {},
                    converter: (store) => store.state,
                    builder: (context, state) {
                      return FloatingActionButton(
                        onPressed: !enabled ? null : () => nextStep(ctx, state),
                        tooltip: '下一步',
                        backgroundColor:
                            !enabled ? Colors.grey[200] : Colors.teal,
                        elevation: 0.0,
                        child: Icon(
                          Icons.chevron_right,
                          color: !enabled ? Colors.black26 : Colors.white,
                          size: 48,
                        ),
                      );
                    });
              },
            ),
    );
  }
}

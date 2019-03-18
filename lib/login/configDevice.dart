import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import './ble.dart';
import '../common/utils.dart';

enum Status {
  auth,
  wifi,
  authFailed,
  connecting,
  binding,
  bindFailed,
  login,
  loginFailed,
  success
}

class ConfigDevice extends StatefulWidget {
  ConfigDevice({Key key, this.device}) : super(key: key);
  final BluetoothDevice device;
  @override
  _ConfigDeviceState createState() => _ConfigDeviceState();
}

class _ConfigDeviceState extends State<ConfigDevice> {
  String selected;
  String token;

  /// The wifi ssid which current phone connected.
  String ssid;

  /// password for Wi-Fi
  String pwd = '';

  Status status = Status.auth;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// check color code
  Future<String> checkCode(BluetoothDevice device, String code) async {
    final authCommand = '{"action":"auth","seq":2,"code":"$code"}';
    final res = await getLocalAuth(device, authCommand);
    String token = res['data']['token'];
    print(res);
    print(token);
    return token;
  }

  /// check color code
  Future<String> setWifi(String wifiPwd) async {
    assert(token != null);
    assert(ssid != null);
    final device = widget.device;
    final wifiCommand =
        '{"action":"addAndActive", "seq": 123, "token": "$token", "body":{"ssid":"$ssid", "pwd":"$wifiPwd"}}';
    final wifiRes = await connectWifi(device, wifiCommand);
    final ip = wifiRes['data']['address'];
    print('ip $wifiRes');
    print('ip $ip');
    return ip;
  }

  Future<void> startBind(String ip, String token) async {
    print('startBind $ip, $token');
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      status = Status.binding;
    });
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      status = Status.success;
    });
  }

  void nextStep(BuildContext ctx) async {
    if (status == Status.auth) {
      print('code is $selected');
      // reset token

      showLoading(ctx);
      try {
        // request token
        token = await checkCode(widget.device, selected);
        if (token == null) throw 'no token';

        // request current wifi ssid, TODO: not connect to wifi
        try {
          ssid = await getWifiSSID();
        } catch (e) {
          print(e);
          ssid = null;
        }

        Navigator.pop(ctx);
        setState(() {
          status = Status.wifi;
        });
      } catch (e) {
        print(e);
        Navigator.pop(ctx);
        setState(() {
          status = Status.authFailed;
        });
      }
    } else if (status == Status.wifi) {
      showLoading(ctx);
      try {
        print('pwd: $pwd');
        final ip = await setWifi(pwd);
        setState(() {
          status = Status.connecting;
        });
        startBind(ip, token).catchError(print);
        Navigator.pop(ctx);
      } catch (e) {
        Navigator.pop(ctx);
        showSnackBar(ctx, '设备连接网络失败，请确认密码是否正确');
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

  Widget renderWifi() {
    String ssid = 'Naxian800';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(16),
          child: Text(
            '配置Wi-Fi',
            style: TextStyle(color: Colors.black87, fontSize: 28),
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            '配置设备的Wi-Fi，使手机与设备连至同一网络',
            style: TextStyle(color: Colors.black54),
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: '设备将连接至 ',
                style: TextStyle(color: Colors.black54),
              ),
              TextSpan(
                text: ssid,
                style: TextStyle(fontSize: 18),
              ),
              TextSpan(
                text: ' , 请输入该Wi-Fi的密码: ',
                style: TextStyle(color: Colors.black54),
              ),
            ]),
          ),
        ),
        Container(
          padding: EdgeInsets.all(16),
          child: TextField(
            autofocus: true,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.lock, color: Colors.teal),
            ),
            onChanged: (text) {
              setState(() {
                pwd = text;
              });
            },
            style: TextStyle(fontSize: 24, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget renderFailed() {
    return Container(
      color: Colors.white,
      height: 256,
      child: Center(
        child: Text('验证失败，请重启设备后再重试'),
      ),
    );
  }

  Widget renderBind() {
    String text = '';
    String buttonLabel;
    switch (status) {
      case Status.connecting:
        text = '连接设备中...';
        break;

      case Status.binding:
        text = '绑定设备中...';
        break;

      case Status.success:
        text = '绑定成功';
        buttonLabel = '进入设备';
        break;

      case Status.bindFailed:
        text = '绑定失败';
        buttonLabel = '重试';
        break;

      case Status.bindFailed:
        text = '绑定失败';
        buttonLabel = '重试';
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
            '绑定设备',
            style: TextStyle(color: Colors.black87, fontSize: 28),
          ),
        ),
        Container(
          height: 160,
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
                  onPressed: () => Navigator.pop(context),
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
            : Center(child: CircularProgressIndicator()),
      ],
    );
  }

  Widget renderBody() {
    switch (status) {
      case Status.auth:
        return renderAuth();

      case Status.wifi:
        return renderWifi();

      case Status.authFailed:
        return renderFailed();

      default:
        return renderBind();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasFab = status == Status.auth || status == Status.wifi;
    bool hasBack = status == Status.auth || status == Status.wifi;
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0, // no shadow
        backgroundColor: Colors.grey[50],
        automaticallyImplyLeading: hasBack,
        brightness: Brightness.light,
        iconTheme: IconThemeData(color: Colors.black38),
      ),
      body: renderBody(),
      floatingActionButton: !hasFab
          ? null
          : Builder(
              builder: (ctx) {
                bool disabled = selected == null;
                return FloatingActionButton(
                  onPressed: disabled ? null : () => nextStep(ctx),
                  tooltip: '下一步',
                  backgroundColor: disabled ? Colors.grey[200] : Colors.teal,
                  elevation: 0.0,
                  child: Icon(
                    Icons.chevron_right,
                    color: disabled ? Colors.black26 : Colors.white,
                    size: 48,
                  ),
                );
              },
            ),
    );
  }
}

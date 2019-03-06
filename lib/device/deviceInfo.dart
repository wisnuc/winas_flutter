import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import './info.dart';
import '../redux/redux.dart';
import '../common/utils.dart';

Widget _ellipsisText(String text) {
  return ellipsisText(text, style: TextStyle(color: Colors.black38));
}

class Auth extends StatelessWidget {
  final Info info;

  Auth(this.info);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Account>(
        onInit: (store) => {},
        onDispose: (store) => {},
        converter: (store) => store.state.account,
        builder: (context, account) {
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
                    '设备身份',
                    style: TextStyle(color: Colors.black87, fontSize: 21),
                  ),
                ),
                Container(height: 16),
                actionButton(
                  '设备SN',
                  () => {},
                  _ellipsisText(info.sn),
                ),
                actionButton(
                  '证书',
                  () => {},
                  _ellipsisText(info.cert),
                ),
                actionButton(
                  '证书指纹',
                  () => {},
                  _ellipsisText(info.fingerprint),
                ),
                actionButton(
                  '证书签发身份',
                  () => {},
                  _ellipsisText(info.signer),
                ),
                actionButton(
                  '证书签发时间',
                  () => {},
                  _ellipsisText(info.certNotBefore),
                ),
                actionButton(
                  '证书有效期至',
                  () => {},
                  _ellipsisText(info.certNotAfter),
                ),
              ],
            ),
          );
        });
  }
}

class DeviceInfo extends StatefulWidget {
  DeviceInfo({Key key}) : super(key: key);
  @override
  _DeviceInfoState createState() => _DeviceInfoState();
}

class _DeviceInfoState extends State<DeviceInfo> {
  Info info;
  bool loading = true;
  bool failed = false;

  refresh(AppState state) async {
    try {
      final res = await state.apis.req('winasInfo', null);
      info = Info.fromMap(res.data);
      if (this.mounted) {
        setState(() {
          loading = false;
          failed = false;
        });
      }
    } catch (error) {
      print(error);
      if (this.mounted) {
        setState(() {
          loading = false;
          failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Account>(
        onInit: (store) => refresh(store.state),
        onDispose: (store) => {},
        converter: (store) => store.state.account,
        builder: (context, account) {
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
                    '关于本机',
                    style: TextStyle(color: Colors.black87, fontSize: 21),
                  ),
                ),
                Container(height: 16),
                loading
                    ? Container(
                        height: 256,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : (info == null || failed)
                        ? Container(
                            height: 256,
                            child: Center(
                              child: Text('加载页面失败'),
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              actionButton(
                                '蓝牙地址',
                                () => {},
                                _ellipsisText(info.bleAddr),
                              ),
                              actionButton(
                                '加密芯片',
                                () => {},
                                _ellipsisText(info.eccName),
                              ),
                              actionButton(
                                '网卡带宽',
                                () => {},
                                _ellipsisText(info.bandwidth),
                              ),
                              actionButton(
                                '设备身份',
                                () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) {
                                      return Auth(info);
                                    }),
                                  );
                                },
                                null,
                              ),
                            ],
                          ),
              ],
            ),
          );
        });
  }
}

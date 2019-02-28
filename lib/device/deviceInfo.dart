import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import '../common/format.dart';
import '../redux/redux.dart';

Widget _actionItem(String title, Function action, Widget rightItem) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: action,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 1.0, color: Colors.grey[200]),
          ),
        ),
        child: Container(
          height: 64,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
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

Widget _ellipsisText(String text) {
  return Expanded(
    child: Text(
      text ?? '',
      textAlign: TextAlign.end,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      style: TextStyle(color: Colors.black38),
    ),
    flex: 10,
  );
}

class Info {
  String bleAddr;
  String eccName;
  String bandwidth;
  String sn;
  String cert;

  String fingerprint;
  String signer;
  String certNotBefore;
  String certNotAfter;
  Info.fromMap(Map m) {
    final device = m['device'];
    final net = m['net'];
    this.bleAddr = device['bleAddr'];
    this.eccName = device['ecc'];
    this.bandwidth = '${net['networkInterface']['speed']} Mbps';
    this.sn = device['sn'];
    this.cert = device['cert'];

    this.fingerprint = device['fingerprint'];
    this.signer = device['signer'];
    this.certNotBefore = prettyDate(device['notBefore']);
    this.certNotAfter = prettyDate(device['notAfter']);
  }
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
                _actionItem(
                  '设备SN',
                  () => {},
                  _ellipsisText(info.sn),
                ),
                _actionItem(
                  '证书',
                  () => {},
                  _ellipsisText(info.cert),
                ),
                _actionItem(
                  '证书指纹',
                  () => {},
                  _ellipsisText(info.fingerprint),
                ),
                _actionItem(
                  '证书签发身份',
                  () => {},
                  _ellipsisText(info.signer),
                ),
                _actionItem(
                  '证书签发时间',
                  () => {},
                  _ellipsisText(info.certNotBefore),
                ),
                _actionItem(
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

  refresh(AppState state) async {
    try {
      final res = await state.apis.req('winasInfo', null);
      info = Info.fromMap(res.data);
      if (this.mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (error) {
      print(error);
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
                info == null
                    ? Container(
                        height: 256,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _actionItem(
                            '蓝牙地址',
                            () => {},
                            _ellipsisText(info.bleAddr),
                          ),
                          _actionItem(
                            '加密芯片',
                            () => {},
                            _ellipsisText(info.eccName),
                          ),
                          _actionItem(
                            '网卡带宽',
                            () => {},
                            _ellipsisText(info.bandwidth),
                          ),
                          _actionItem(
                            '设备身份',
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    fullscreenDialog: true,
                                    builder: (context) {
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

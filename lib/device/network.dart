import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import './info.dart';
import '../redux/redux.dart';
import '../common/utils.dart';

class Network extends StatefulWidget {
  Network({Key key}) : super(key: key);
  @override
  _NetworkState createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  Info info;
  bool loading = true;
  bool failed = false;

  Widget _ellipsisText(String text) {
    return ellipsisText(text, style: TextStyle(color: Colors.black38));
  }

  refresh(AppState state) async {
    try {
      final res = await state.apis.req('winasInfo', null);
      info = Info.fromMap(res.data);
      print('info: $info');
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
              // actions: <Widget>[
              //   Builder(builder: (ctx) {
              //     return FlatButton(
              //       child: Text(
              //         '切换Wi-Fi',
              //         style: TextStyle(color: Colors.black54),
              //       ),
              //       onPressed: () {},
              //     );
              //   })
              // ],
            ),
            body: loading
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
                          Container(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              '设备网络',
                              style: TextStyle(
                                  color: Colors.black87, fontSize: 21),
                            ),
                          ),
                          Container(height: 16),
                          actionButton(
                            'Wi-Fi名称',
                            () => {},
                            _ellipsisText(info.interfaceName),
                          ),
                          actionButton(
                            '局域网IP地址',
                            () => {},
                            _ellipsisText(info.address),
                          ),
                          actionButton(
                            '网卡带宽',
                            () => {},
                            _ellipsisText(info.bandwidth),
                          ),
                        ],
                      ),
          );
        });
  }
}

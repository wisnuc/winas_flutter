import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../common/utils.dart';
import '../redux/redux.dart';

class Network extends StatefulWidget {
  Network({Key key}) : super(key: key);
  @override
  _NetworkState createState() => _NetworkState();
}

class _NetworkState extends State<Network> {
  @override
  void initState() {
    super.initState();
  }

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
                    '设备网络',
                    style: TextStyle(color: Colors.black87, fontSize: 21),
                  ),
                ),
                Container(height: 16),
                actionButton(
                  'IP地址',
                  () => {},
                  Row(
                    children: <Widget>[
                      Container(
                        height: 48,
                        width: 48,
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(24),
                          ),
                          child: account.avatarUrl == null
                              ? Icon(
                                  Icons.account_circle,
                                  color: Colors.blueGrey,
                                  size: 48,
                                )
                              : Image.network(
                                  account.avatarUrl,
                                ),
                        ),
                      ),
                      Container(width: 8),
                      Icon(Icons.chevron_right, color: Colors.black38),
                    ],
                  ),
                ),
                actionButton(
                  '昵称',
                  () => {},
                  Row(
                    children: <Widget>[
                      Text(
                        account.nickName,
                        style: TextStyle(color: Colors.black38),
                      ),
                      Container(width: 8),
                      Icon(Icons.chevron_right, color: Colors.black38),
                    ],
                  ),
                ),
                actionButton(
                  '账户名',
                  () => {},
                  Text(
                    account.username,
                    style: TextStyle(color: Colors.black38),
                  ),
                ),
              ],
            ),
          );
        });
  }
}

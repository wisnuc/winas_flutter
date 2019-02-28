import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import './weChat.dart';
import '../redux/redux.dart';

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

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Account>(
        onInit: (store) => {},
        onDispose: (store) => {},
        converter: (store) => store.state.account,
        builder: (context, account) {
          if (!(account is Account)) return Container();
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
                    '个人中心',
                    style: TextStyle(color: Colors.black87, fontSize: 21),
                  ),
                ),
                Container(height: 16),
                actionItem(
                  '头像',
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
                actionItem(
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
                actionItem(
                  '账户名',
                  () => {},
                  Text(
                    account.username,
                    style: TextStyle(color: Colors.black38),
                  ),
                ),
                actionItem(
                  '微信',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return WeChat();
                      }),
                    );
                  },
                  Row(
                    children: <Widget>[
                      Text(
                        '详情',
                        style: TextStyle(color: Colors.black38),
                      ),
                      Container(width: 8),
                      Icon(Icons.chevron_right, color: Colors.black38),
                    ],
                  ),
                ),
                StoreConnector<AppState, VoidCallback>(
                  converter: (store) => () {
                        // remove account, apis, device
                        store.dispatch(LoginAction(null));
                        store.dispatch(UpdateApisAction(null));
                        store.dispatch(DeviceLoginAction(null));
                      },
                  builder: (context, logout) {
                    return actionItem(
                      '注销',
                      () {
                        logout();
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      Container(),
                    );
                  },
                ),
              ],
            ),
          );
        });
  }
}

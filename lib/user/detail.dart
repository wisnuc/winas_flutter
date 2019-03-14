import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import './weChat.dart';
import './avatarView.dart';
import './newNickName.dart';
import '../redux/redux.dart';
import '../common/utils.dart';

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
                actionButton(
                  '头像',
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) {
                          return AvatarView(avatarUrl: account.avatarUrl);
                        },
                      ),
                    );
                  },
                  Row(
                    children: <Widget>[
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: account.avatarUrl == null
                              ? null
                              : Border.all(color: Colors.grey[400]),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.all(
                            Radius.circular(24),
                          ),
                          child: account.avatarUrl == null
                              ? Center(
                                  child: Icon(
                                    Icons.account_circle,
                                    color: Colors.blueGrey,
                                    size: 48,
                                  ),
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
                  () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) {
                          return NewNickName(nickName: account.nickName);
                        },
                        fullscreenDialog: true,
                      ),
                    );
                  },
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
                actionButton(
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
                        // cancel network monitor
                        store.state.apis.monitorCancel();

                        // remove account, apis, device, reset config
                        store.dispatch(LoginAction(null));
                        store.dispatch(UpdateApisAction(null));
                        store.dispatch(DeviceLoginAction(null));
                        store.dispatch(UpdateConfigAction(Config()));
                      },
                  builder: (context, logout) {
                    return actionButton(
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

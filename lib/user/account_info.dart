import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/material.dart';

import '../redux/redux.dart';

class AccountInfo extends StatefulWidget {
  AccountInfo({Key key}) : super(key: key);

  @override
  _AccountInfoState createState() => new _AccountInfoState();
}

class _AccountInfoState extends State<AccountInfo> {
  Widget actionItem(String title, Function action, Widget rightItem) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1.0, color: Colors.grey[200]),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Account>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store.state.account,
      builder: (context, account) {
        return Scaffold(
          body: Container(
            constraints: BoxConstraints.expand(),
            padding: EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                Container(height: 56),
                GestureDetector(
                  onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return Scaffold(
                            appBar: AppBar(),
                            body: Container(),
                          );
                        }),
                      ),
                  child: Container(
                    height: 72,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          flex: 10,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                account.nickName,
                                style: TextStyle(fontSize: 28),
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              Text(
                                '查看并编辑个人资料',
                                style: TextStyle(fontSize: 14),
                                textAlign: TextAlign.start,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Container(),
                          flex: 1,
                        ),
                        Container(
                          height: 56,
                          width: 56,
                          child: ClipRRect(
                            borderRadius: BorderRadius.all(
                              Radius.circular(28),
                            ),
                            child: Image.network(
                              account.avatarUrl,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(height: 16),
                actionItem(
                  '账户安全',
                  () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return Scaffold(
                            appBar: AppBar(),
                            body: Container(),
                          );
                        }),
                      ),
                  null,
                ),
                actionItem(
                  '语言',
                  () => {},
                  Text('中文'),
                ),
                actionItem(
                  '清除缓存',
                  () => {},
                  Text('1 MB'),
                ),
                actionItem(
                  '关于',
                  () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return Scaffold(
                            appBar: AppBar(),
                            body: Container(),
                          );
                        }),
                      ),
                  null,
                ),
                actionItem(
                  '注销',
                  () => Navigator.pushReplacementNamed(context, '/login'),
                  Container(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

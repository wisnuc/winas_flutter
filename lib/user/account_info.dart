import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/material.dart';

import './about.dart';
import './detail.dart';
import '../common/cache.dart';
import '../redux/redux.dart';
import '../common/format.dart';

class AccountInfo extends StatefulWidget {
  AccountInfo({Key key}) : super(key: key);

  @override
  _AccountInfoState createState() => new _AccountInfoState();
}

class _AccountInfoState extends State<AccountInfo> {
  int cacheSize;

  Future getCacheSize() async {
    final cm = await CacheManager.getInstance();
    var size = await cm.getCacheSize();
    if (this.mounted) {
      setState(() {
        cacheSize = size;
      });
    }
  }

  Future clearCache(BuildContext ctx) async {
    final cm = await CacheManager.getInstance();
    await cm.clearCache();
    await getCacheSize();
    Navigator.pop(ctx);
  }

  @override
  void initState() {
    super.initState();
    getCacheSize();
  }

  Widget actionItem(String title, Function action, Widget rightItem) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action,
        child: Container(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          height: 64,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(width: 1.0, color: Colors.grey[200]),
            ),
          ),
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
        if (account == null) return Container();
        return Scaffold(
          appBar: AppBar(
            elevation: 0.0, // no shadow
            backgroundColor: Colors.white10,
            brightness: Brightness.light,
          ),
          body: Container(
            child: Column(
              children: <Widget>[
                GestureDetector(
                  onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return Detail();
                        }),
                      ),
                  child: Container(
                    height: 72,
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
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
                            child: account.avatarUrl == null
                                ? Icon(
                                    Icons.account_circle,
                                    color: Colors.blueGrey,
                                    size: 56,
                                  )
                                : Image.network(
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
                  () async {
                    await showDialog(
                      context: this.context,
                      builder: (BuildContext context) => AlertDialog(
                            title: Text('清除缓存'),
                            content: Text('该操作将清除所有缓存的图片、文件'),
                            actions: <Widget>[
                              FlatButton(
                                  textColor: Theme.of(context).primaryColor,
                                  child: Text('取消'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                  }),
                              FlatButton(
                                textColor: Theme.of(context).primaryColor,
                                child: Text('确定'),
                                onPressed: () => clearCache(context),
                              )
                            ],
                          ),
                    );
                  },
                  Text(cacheSize != null ? prettySize(cacheSize) : ''),
                ),
                actionItem(
                  '关于',
                  () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return About();
                        }),
                      ),
                  null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

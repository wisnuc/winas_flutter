import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/material.dart';
import '../redux/redux.dart';

class AvatarView extends StatefulWidget {
  AvatarView({Key key, this.avatarUrl}) : super(key: key);
  final String avatarUrl;
  @override
  _AvatarViewState createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView> {
  String avatarUrl;
  String filePath;
  String _error;
  bool loading = false;

  _onPressed(context, store) async {
    AppState state = store.state;
    Account account = state.account;

    setState(() {
      loading = true;
    });
    try {
      final res = await state.cloud.setAvatar(filePath);

      // update Account in store
      account.updateAvatar(res.avatarUrl);
      store.dispatch(LoginAction(account));
    } catch (error) {
      print(error.response.data);
      setState(() {
        loading = false;
        _error = '操作失败';
      });
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  void initState() {
    super.initState();
    avatarUrl = widget.avatarUrl;
  }

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
            backgroundColor: Colors.black,
            brightness: Brightness.dark,
            iconTheme: IconThemeData(color: Colors.white),
            title: Text(
              '个人头像',
              style: TextStyle(color: Colors.white),
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(Icons.more_horiz),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext c) {
                      return Container(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Material(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(c);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  child: Text('拍照'),
                                ),
                              ),
                            ),
                            Material(
                              child: InkWell(
                                onTap: () {
                                  Navigator.pop(c);
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16),
                                  child: Text('从相册选取'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              )
            ],
          ),
          body: Container(
            color: Colors.black,
            constraints: BoxConstraints.expand(),
            child: Center(
              child: Container(
                width: double.infinity,
                child: Container(
                  child: avatarUrl == null
                      ? Icon(
                          Icons.account_circle,
                          color: Colors.blueGrey,
                          size: 48,
                        )
                      : Image.network(
                          avatarUrl,
                          fit: BoxFit.fitWidth,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

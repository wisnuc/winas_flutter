import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/material.dart';
import '../redux/redux.dart';

class NewNickName extends StatefulWidget {
  NewNickName({Key key, this.nickName}) : super(key: key);
  final String nickName;
  @override
  _NewNickNameState createState() => _NewNickNameState();
}

class _NewNickNameState extends State<NewNickName> {
  String _newName;
  String _error;
  bool loading = false;

  _onPressed(context, store) async {
    AppState state = store.state;
    Account account = state.account;

    setState(() {
      loading = true;
    });
    try {
      await state.cloud.req('newNickName', {
        'nickName': _newName,
      });

      // update Account in store
      account.updateNickName(_newName);
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

  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _newName = widget.nickName;
    _controller = TextEditingController(text: _newName);
  }

  @override
  Widget build(BuildContext context) {
    bool disabled = loading || _newName == null || _newName == widget.nickName;
    return StoreConnector<AppState, AppState>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0.0, // no shadow
            backgroundColor: Colors.white10,
            brightness: Brightness.light,
            iconTheme: IconThemeData(color: Colors.black38),
          ),
          body: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '设置昵称',
                    style: TextStyle(fontSize: 21),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    '设置专属个性昵称',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    key: Key('account'),
                    onChanged: (text) {
                      setState(() {
                        _error = null;
                        _newName = text;
                      });
                    },
                    decoration: InputDecoration(errorText: _error),
                    controller: _controller,
                    autofocus: true,
                    style: TextStyle(fontSize: 28, color: Colors.black87),
                  ),
                ),
                Container(height: 32),
                Center(
                  child: loading ? CircularProgressIndicator() : Container(),
                ),
              ],
            ),
          ),
          floatingActionButton: Builder(
            builder: (ctx) {
              return StoreConnector<AppState, VoidCallback>(
                converter: (store) => () => _onPressed(ctx, store),
                builder: (context, callback) => FloatingActionButton(
                      onPressed: disabled ? null : callback,
                      tooltip: '确定',
                      backgroundColor: disabled ? Colors.grey : Colors.teal,
                      elevation: 0.0,
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
              );
            },
          ),
        );
      },
    );
  }
}

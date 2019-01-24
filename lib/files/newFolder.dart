import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/material.dart';
import '../redux/redux.dart';

class NewFolder extends StatefulWidget {
  NewFolder({Key key, this.node}) : super(key: key);
  final Node node;
  @override
  _NewFolderState createState() => _NewFolderState(node);
}

class _NewFolderState extends State<NewFolder> {
  _NewFolderState(this.node);
  String _fileName;
  String _error;
  bool loading = false;
  final Node node;

  _onPressed(context, state) async {
    print(_fileName);

    setState(() {
      loading = true;
    });

    try {
      await state.apis.req('mkdir', {
        'dirname': _fileName,
        'dirUUID': node.dirUUID,
        'driveUUID': node.driveUUID,
      });
    } catch (error) {
      print(error);
      setState(() {
        loading = false;
        _error = '创建失败';
      });
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return AlertDialog(
          title: Text('新建文件夹'),
          content: TextField(
            autofocus: true,
            onChanged: (text) {
              setState(() => _error = null);
              _fileName = text;
            },
            decoration: InputDecoration(errorText: _error),
            style: TextStyle(fontSize: 24, color: Colors.black87),
          ),
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
              onPressed: () => _onPressed(context, state),
            )
          ],
        );
      },
    );
  }
}

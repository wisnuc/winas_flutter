import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

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
    if (!isEnabled()) return;

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
      _error = '创建失败';
      if (error is DioError && error?.response?.data is Map) {
        final res = error.response.data;
        print(res);
        if (res['code'] == 'EEXIST') {
          _error = res['xcode'] == 'EISFILE' ? '存在同名的文件' : '同名文件夹已经存在';
        } else if (res['message'] == 'invalid name') {
          _error = '名称不合法，如不能包含 \\/?<>*:"| 等字符';
        }
      } else {
        print(error);
      }

      setState(() {
        loading = false;
      });
      return;
    }

    Navigator.pop(context, true);
  }

  bool isEnabled() {
    return loading == false &&
        _error == null &&
        _fileName is String &&
        _fileName.length > 0;
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
              onPressed: isEnabled() ? () => _onPressed(context, state) : null,
            )
          ],
        );
      },
    );
  }
}

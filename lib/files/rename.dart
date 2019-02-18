import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/material.dart';
import '../redux/redux.dart';

class RenameDialog extends StatefulWidget {
  RenameDialog({Key key, this.entry}) : super(key: key);

  final Entry entry;
  @override
  _RenameDialogState createState() => _RenameDialogState(entry);
}

class _RenameDialogState extends State<RenameDialog> {
  _RenameDialogState(this.entry) : _fileName = entry.name;
  String _fileName;
  String _error;
  bool loading = false;

  final Entry entry;

  _onPressed(context, state) async {
    setState(() {
      loading = true;
    });

    try {
      await state.apis.req('rename', {
        'oldName': entry.name,
        'newName': _fileName,
        'dirUUID': entry.pdir,
        'driveUUID': entry.pdrv,
      });
    } catch (error) {
      print(error);
      setState(() {
        loading = false;
        _error = '重命名失败';
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
          title: Text('重命名'),
          content: TextField(
            autofocus: true,
            onChanged: (text) {
              setState(() => _error = null);
              _fileName = text;
            },
            // controller: TextEditingController(text: _fileName),
            // controller: TextEditingController.fromValue(
            //   TextEditingValue(
            //     text: _fileName,
            //     selection: TextSelection.collapsed(offset: _fileName.length),
            //   ),
            // ),
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

import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../redux/redux.dart';

class DeleteDialog extends StatefulWidget {
  DeleteDialog({Key key, this.entries}) : super(key: key);
  final List<Entry> entries;
  @override
  _DeleteDialogState createState() => _DeleteDialogState(entries);
}

class _DeleteDialogState extends State<DeleteDialog> {
  _DeleteDialogState(this.entries);
  String _fileName;
  String _error;
  bool loading = false;
  final List<Entry> entries;

  _onPressed(context, state) async {
    print(_fileName);

    setState(() {
      loading = true;
    });

    try {
      Map<String, dynamic> formdata = Map();
      List<Entry> sortedEntries = entries.toList();
      List<List<Entry>> newEntries = [];
      sortedEntries.sort((a, b) => a.pdir.compareTo(b.pdir));

      for (Entry entry in sortedEntries) {
        if (newEntries.length == 0) {
          newEntries.add([entry]);
        } else if (newEntries[newEntries.length - 1][0].pdir == entry.pdir) {
          newEntries[newEntries.length - 1].add(entry);
        } else {
          newEntries.add([entry]);
        }
      }
      for (List<Entry> entries in newEntries) {
        entries.forEach((e) {
          formdata[e.name] =
              jsonEncode({'op': 'remove', 'uuid': e.uuid, 'hash': e.hash});
        });

        await state.apis.req('deleteDirOrFile', {
          'formdata': FormData.from(formdata),
          'dirUUID': entries[0].pdir,
          'driveUUID': entries[0].pdrv,
        });
      }
    } catch (error) {
      print(error);
      setState(() {
        loading = false;
        _error = '删除失败';
        print(_error);
      });
      // Navigator.pop(context, false);
      return;
    }
    // TODO: fix delete
    // Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return AlertDialog(
          title: Text('删除文件或文件夹'),
          content: Text('确定删除选择的文件或文件夹吗？'),
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

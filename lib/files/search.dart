import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux/redux.dart';
import '../icons/winas_icons.dart';
import '../common/renderIcon.dart';

class Search extends StatefulWidget {
  Search({Key key, this.node}) : super(key: key);
  final Node node;

  @override
  _SearchState createState() => _SearchState(node);
}

class _SearchState extends State<Search> {
  _SearchState(this.node);
  String _fileName;
  String _error;
  bool loading = false;
  final Node node;

  _onPressed(context, state) async {
    setState(() {
      loading = true;
    });

    try {
      await state.apis.req('rename', {
        'newName': _fileName,
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

  // [title, icon, types]
  List<List> actions = [
    [
      'PDFs',
      renderIcon('a.pdf', null),
      'PDF',
    ],
    [
      'Word',
      renderIcon('a.docx', null),
      'DOCX.DOC',
    ],
    [
      'Excel',
      renderIcon('a.xlsx', null),
      'XLSX.XLS',
    ],
    [
      'PPT',
      renderIcon('a.ppt', null),
      'PPTX.PPT',
    ],
    [
      '照片与图片',
      renderIcon('a.bmp', null),
      'JPEG.PNG.JPG.GIF.BMP.RAW',
    ],
    [
      '视频',
      renderIcon('a.mkv', null),
      'RM.RMVB.WMV.AVI.MP4.3GP.MKV.MOV.FLV',
    ],
    [
      '音频',
      renderIcon('a.mp3', null),
      'WAV.MP3.APE.WMA.FLAC',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            elevation: 2.0, // no shadow
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black38),
            title: TextField(
              // autofocus: true,
              onChanged: (text) {
                setState(() => _error = null);
                _fileName = text;
              },
              decoration: InputDecoration(
                errorText: _error,
                border: InputBorder.none,
                hintText: '搜索文件',
              ),
              style: TextStyle(color: Colors.black87),
            ),
          ),
          body: Container(
            child: Column(children: [
              Container(
                height: 56,
                child: Row(
                  children: <Widget>[
                    Container(width: 16),
                    Text('文件类型'),
                  ],
                ),
              ),
              Column(
                children: actions
                    .map((a) => InkWell(
                          onTap: () => {},
                          child: Container(
                            height: 56,
                            child: Row(
                              children: <Widget>[
                                Container(width: 16),
                                a[1],
                                Container(width: 32),
                                Text(a[0]),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              )
            ]),
          ),
        );
      },
    );
  }
}

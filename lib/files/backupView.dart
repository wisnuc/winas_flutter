import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/material.dart';
import '../redux/redux.dart';

class BackupView extends StatefulWidget {
  BackupView({Key key}) : super(key: key);

  @override
  _BackupViewState createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  Future refresh(state) async {}
  ScrollController myScrollController = ScrollController();
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, AppState>(
      onInit: (store) => refresh(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white10,
            brightness: Brightness.light,
            iconTheme: IconThemeData(color: Colors.black38),
            title: Text('设备', style: TextStyle(color: Colors.black87)),
            elevation: 0.0, // no shadow
          ),
          body: Container(
            color: Colors.white10,
            constraints: BoxConstraints.expand(),
            child: Scrollbar(
              child: ListView.builder(
                  itemCount: 100,
                  itemExtent: 50.0,
                  controller: myScrollController,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text("$index"),
                    );
                  }),
            ),
          ),
        );
      },
    );
  }
}

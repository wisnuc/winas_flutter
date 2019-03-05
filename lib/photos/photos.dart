import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import '../redux/redux.dart';
import '../common/utils.dart';

class Photos extends StatefulWidget {
  Photos({Key key}) : super(key: key);

  @override
  _PhotosState createState() => new _PhotosState();
}

class _PhotosState extends State<Photos> {
  bool loading = true;

  Future refresh(AppState state) async {
    await Future.delayed(Duration(seconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final list = [1, 2, 3, 4, 5, 6, 7];
    return StoreConnector<AppState, AppState>(
      onInit: (store) =>
          refresh(store.state).catchError((error) => print(error)),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            elevation: 2.0, // shadow
            brightness: Brightness.light,
            backgroundColor: Colors.white,
            iconTheme: IconThemeData(color: Colors.black38),
            title: Text('相簿', style: TextStyle(color: Colors.black87)),
          ),
          body: loading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Container(
                  padding: EdgeInsets.all(16),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      return Material(
                        child: InkWell(
                          onTap: () => {},
                          child: Column(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Container(
                                  color: Colors.grey[300],
                                ),
                              ),
                              Container(
                                color: Colors.grey[200],
                                height: 48,
                                child: Center(
                                  child: Text(index.toString()),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}

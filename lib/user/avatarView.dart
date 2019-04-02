import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:image_cropper/image_cropper.dart';

import '../redux/redux.dart';
import '../common/utils.dart';

class AvatarView extends StatefulWidget {
  AvatarView({Key key, this.avatarUrl}) : super(key: key);
  final String avatarUrl;
  @override
  _AvatarViewState createState() => _AvatarViewState();
}

class _AvatarViewState extends State<AvatarView> {
  String avatarUrl;
  File imageFile;

  Future getImage(BuildContext ctx, store, {bool camera}) async {
    final rawFile = await ImagePicker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
    );
    if (rawFile == null) return;
    final cropFile = await ImageCropper.cropImage(
      toolbarColor: Colors.black,
      toolbarTitle: '照片编辑',
      sourcePath: rawFile.path,
      ratioX: 1.0,
      ratioY: 1.0,
      maxWidth: 512,
      maxHeight: 512,
    );

    showLoading(ctx);
    setState(() {
      imageFile = cropFile;
    });

    AppState state = store.state;
    Account account = state.account;

    try {
      // await Future.delayed(Duration(seconds: 2));
      final List<int> imageData = await imageFile.readAsBytes();
      final res = await state.cloud.setAvatar(imageData);
      // update Account in store
      final String url = res.data;
      print(url);
      if (url.startsWith('https')) {
        account.updateAvatar(url);
        store.dispatch(LoginAction(account));
      } else {
        throw Error();
      }
      Navigator.pop(ctx);
      showSnackBar(ctx, '头像修改成功');
    } catch (error) {
      print(error);
      Navigator.pop(ctx);
      showSnackBar(ctx, '上传头像失败');
    }
  }

  @override
  void initState() {
    super.initState();
    avatarUrl = widget.avatarUrl;
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, dynamic>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store,
      builder: (context, store) {
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
              Builder(
                builder: (ctx) {
                  return IconButton(
                    icon: Icon(Icons.more_horiz),
                    onPressed: () {
                      showModalBottomSheet(
                        context: ctx,
                        builder: (BuildContext c) {
                          return SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Material(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pop(c);
                                      getImage(ctx, store, camera: true);
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
                                      getImage(ctx, store, camera: false);
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
                  child: imageFile is File
                      ? Image.file(
                          imageFile,
                          fit: BoxFit.fitWidth,
                        )
                      : avatarUrl == null
                          ? Icon(
                              Icons.account_circle,
                              color: Colors.blueGrey,
                              size: 72,
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

import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';

import './info.dart';
import '../redux/redux.dart';
import '../common/utils.dart';
import '../common/appBarSlivers.dart';

Widget _ellipsisText(String text) {
  return ellipsisText(text, style: TextStyle(color: Colors.black38));
}

class Auth extends StatelessWidget {
  final Info info;

  Auth(this.info);

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Account>(
        onInit: (store) => {},
        onDispose: (store) => {},
        converter: (store) => store.state.account,
        builder: (context, account) {
          return Scaffold(
            appBar: AppBar(
              elevation: 0.0, // no shadow
              backgroundColor: Colors.white10,
              brightness: Brightness.light,
              iconTheme: IconThemeData(color: Colors.black38),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    '设备身份',
                    style: TextStyle(color: Colors.black87, fontSize: 21),
                  ),
                ),
                Container(height: 16),
                sliverActionButton(
                  '设备SN',
                  () => {},
                  _ellipsisText(info.sn),
                ),
                sliverActionButton(
                  '证书',
                  () => {},
                  _ellipsisText(info.cert),
                ),
                sliverActionButton(
                  '证书指纹',
                  () => {},
                  _ellipsisText(info.fingerprint),
                ),
                sliverActionButton(
                  '证书签发身份',
                  () => {},
                  _ellipsisText(info.signer),
                ),
                sliverActionButton(
                  '证书签发时间',
                  () => {},
                  _ellipsisText(info.certNotBefore),
                ),
                sliverActionButton(
                  '证书有效期至',
                  () => {},
                  _ellipsisText(info.certNotAfter),
                ),
              ],
            ),
          );
        });
  }
}

class DeviceInfo extends StatefulWidget {
  DeviceInfo({Key key}) : super(key: key);
  @override
  _DeviceInfoState createState() => _DeviceInfoState();
}

class _DeviceInfoState extends State<DeviceInfo> {
  Info info;
  bool loading = true;
  bool failed = false;
  ScrollController myScrollController = ScrollController();

  /// left padding of appbar
  double paddingLeft = 16;

  /// scrollController's listener to get offset
  void listener() {
    setState(() {
      paddingLeft = (myScrollController.offset * 1.25).clamp(16.0, 72.0);
    });
  }

  @override
  void initState() {
    myScrollController.addListener(listener);
    super.initState();
  }

  @override
  void dispose() {
    myScrollController.removeListener(listener);
    super.dispose();
  }

  void refresh(AppState state) async {
    try {
      final res = await state.apis.req('winasInfo', null);
      info = Info.fromMap(res.data);
      if (this.mounted) {
        setState(() {
          loading = false;
          failed = false;
        });
      }
    } catch (error) {
      print(error);
      if (this.mounted) {
        setState(() {
          loading = false;
          failed = true;
        });
      }
    }
  }

  List<Widget> getSlivers() {
    final String titleName = '关于本机';
    // title
    List<Widget> slivers = appBarSlivers(paddingLeft, titleName);
    if (loading) {
      // loading
      slivers.add(SliverToBoxAdapter(child: Container(height: 16)));
    } else if (info == null || failed) {
      // failed
      slivers.add(
        SliverToBoxAdapter(
          child: Container(
            height: 256,
            child: Center(
              child: Text('加载页面失败'),
            ),
          ),
        ),
      );
    } else {
      // actions
      slivers.addAll([
        sliverActionButton(
          '软件版本',
          () => {},
          _ellipsisText('1.0.0'),
        ),
        sliverActionButton(
          '型号',
          () => {},
          _ellipsisText('Winas'),
        ),
        sliverActionButton(
          '序列号',
          () => {},
          _ellipsisText(info.sn),
        ),
        sliverActionButton(
          '蓝牙地址',
          () => {},
          _ellipsisText(info.bleAddr),
        ),
        sliverActionButton(
          '设备证书',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return Auth(info);
              }),
            );
          },
          null,
        ),
        sliverActionButton(
          '重置设备',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return Auth(info);
              }),
            );
          },
          null,
        ),
      ]);
    }
    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, Account>(
      onInit: (store) => refresh(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state.account,
      builder: (context, account) {
        return Scaffold(
          body: CustomScrollView(
            controller: myScrollController,
            slivers: getSlivers(),
          ),
        );
      },
    );
  }
}

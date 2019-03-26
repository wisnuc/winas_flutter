import 'package:flutter/material.dart';

import './info.dart';
import '../common/utils.dart';
import '../common/appBarSlivers.dart';

Widget _ellipsisText(String text) {
  return ellipsisText(text, style: TextStyle(color: Colors.black38));
}

/// Infomation of device cert
class Auth extends StatefulWidget {
  Auth({Key key, this.info}) : super(key: key);
  final Info info;
  @override
  _AuthState createState() => _AuthState();
}

class _AuthState extends State<Auth> {
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

  List<Widget> getSlivers() {
    final String titleName = '设备身份';
    final info = widget.info;
    // title
    List<Widget> slivers = appBarSlivers(paddingLeft, titleName);

    // actions
    slivers.addAll([
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
    ]);

    return slivers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        controller: myScrollController,
        slivers: getSlivers(),
      ),
    );
  }
}

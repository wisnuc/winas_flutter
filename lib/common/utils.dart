import 'dart:io';
import 'package:flutter/material.dart';
import 'package:device_info/device_info.dart';

/// showSnackBar, require BuildContext to find Scaffold
void showSnackBar(BuildContext ctx, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    duration: Duration(seconds: 1),
  );

  // Find the Scaffold in the Widget tree and use it to show a SnackBar!
  // Scaffold.of(ctx, nullOk: true)?.showSnackBar(snackBar);
  Scaffold.of(ctx).showSnackBar(snackBar);
}

Future<T> _showLoading<T>({
  @required BuildContext context,
  bool barrierDismissible = true,
  WidgetBuilder builder,
}) {
  return showGeneralDialog(
    context: context,
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      final ThemeData theme = Theme.of(context, shadowThemeOnly: true);
      final Widget pageChild = Builder(builder: builder);
      return SafeArea(
        child: Builder(builder: (BuildContext context) {
          return theme != null
              ? Theme(data: theme, child: pageChild)
              : pageChild;
        }),
      );
    },
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black12,
    transitionDuration: const Duration(milliseconds: 150),
    transitionBuilder: (BuildContext context, Animation<double> animation,
        Animation<double> secondaryAnimation, Widget child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ),
        child: child,
      );
    },
  );
}

/// Show modal loading, need Navigator.pop(context) to close
Future showLoading(BuildContext context, {bool barrierDismissible: false}) {
  return _showLoading(
    barrierDismissible: barrierDismissible,
    builder: (ctx) {
      return Container(
        constraints: BoxConstraints.expand(),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    },
    context: context,
  );
}

class Model {
  Model();
  bool close = false;
  bool get shouldClose => close;
}

void showNormalDialog<T>({BuildContext context, String text, Model model}) {
  showDialog<T>(
    context: context,
    builder: (BuildContext context) => WillPopScope(
          onWillPop: () => Future.value(model.shouldClose),
          child: SimpleDialog(
            elevation: 2.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            children: <Widget>[
              Container(height: 16),
              Center(
                child: CircularProgressIndicator(),
              ),
              Container(height: 16),
              Center(
                child: Text(text),
              ),
              Container(height: 16),
            ],
          ),
        ),
  ).then<void>((T value) {});
}

/// Provide pretty printed file sizes
String prettySize(num size) {
  if (size == null) return '';
  if (size < 1024) return '$size B';
  if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
  if (size < 1024 * 1024 * 1024)
    return '${(size / 1024 / 1024).toStringAsFixed(2)} MB';
  return '${(size / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}

String twoDigits(int n) {
  if (n >= 10) return "$n";
  return "0$n";
}

/// Provide pretty printed date time, result:
///
/// date == false: 2019-03-06 17:46
///
/// date == true: 2019-03-06
String prettyDate(int time, {bool showDay: false, bool showMonth: false}) {
  if (time == null) return '';
  var t = DateTime.fromMillisecondsSinceEpoch(time);
  var year = t.year;
  var month = twoDigits(t.month);
  var day = twoDigits(t.day);
  var hour = twoDigits(t.hour);
  var minute = twoDigits(t.minute);
  if (showMonth) return '$year-$month';
  if (showDay) return '$year-$month-$day';
  return '$year-$month-$day $hour:$minute';
}

/// Ellipsis Text
Widget ellipsisText(String text, {TextStyle style}) {
  return Expanded(
    child: Text(
      text ?? '',
      textAlign: TextAlign.end,
      overflow: TextOverflow.fade,
      softWrap: false,
      maxLines: 1,
      style: style,
    ),
    flex: 10,
  );
}

/// Full width action button with inkwell
Widget actionButton(String title, Function action, Widget rightItem) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: action,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(width: 1.0, color: Colors.grey[200]),
          ),
        ),
        child: Container(
          height: 64,
          padding: EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: <Widget>[
              Text(
                title,
                style: TextStyle(fontSize: 16),
              ),
              Expanded(
                flex: 1,
                child: Container(),
              ),
              rightItem ?? Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    ),
  );
}

/// actionButton as Sliver
Widget sliverActionButton(String title, Function action, Widget rightItem) {
  return SliverToBoxAdapter(child: actionButton(title, action, rightItem));
}

Future getMachineId() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String deviceName;
  String machineId;
  if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    deviceName = iosInfo.name;
    machineId = iosInfo.identifierForVendor;
  } else {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    deviceName = androidInfo.model;
    machineId = androidInfo.androidId;
  }
  return {
    'deviceName': deviceName,
    'machineId': machineId,
  };
}

Future<String> getClientId() async {
  String clientId;
  try {
    final idRes = await getMachineId();
    clientId = idRes['machineId'];
  } catch (e) {
    clientId = 'default_mobile_clientId';
  }
  return clientId;
}

/// Transparent PageRoute
class TransparentPageRoute extends PageRoute<void> {
  TransparentPageRoute({
    @required this.builder,
    RouteSettings settings,
  })  : assert(builder != null),
        super(settings: settings, fullscreenDialog: true);

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration(milliseconds: 350);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    final result = builder(context);
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(animation),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: result,
      ),
    );
  }
}

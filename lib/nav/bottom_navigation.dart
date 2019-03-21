import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:outline_material_icons/outline_material_icons.dart';

import '../user/user.dart';
import '../files/file.dart';
import '../redux/redux.dart';
import '../files/fileRow.dart';
import '../photos/backup.dart';
import '../photos/photos.dart';
import '../files/backupView.dart';
import '../device/myStation.dart';
import '../transfer/transfer.dart';

class NavigationIconView {
  NavigationIconView({
    Widget icon,
    Widget activeIcon,
    Function view,
    String title,
    String nav,
    Color color,
  })  : view = view,
        item = BottomNavigationBarItem(
          icon: icon,
          activeIcon: activeIcon,
          title: Text(title),
          backgroundColor: color,
        );

  final Function view;
  final BottomNavigationBarItem item;
}

List<FileNavView> fileNavViews = [
  FileNavView(
    icon: Icon(Icons.people, color: Colors.white),
    title: '共享空间',
    nav: 'public',
    color: Colors.orange,
    onTap: (context) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return Files(
                node: Node(
                  name: '共享空间',
                  tag: 'built-in',
                  location: 'built-in',
                ),
              );
            },
          ),
        ),
  ),
  FileNavView(
    icon: Icon(Icons.refresh, color: Colors.white),
    title: '备份空间',
    nav: 'backup',
    color: Colors.blue,
    onTap: (context) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BackupView(),
          ),
        ),
  ),
  FileNavView(
    icon: Icon(Icons.swap_vert, color: Colors.white),
    title: '传输任务',
    nav: 'transfer',
    color: Colors.purple,
    onTap: (context) => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Transfer(),
          ),
        ),
  ),
];

class BottomNavigation extends StatefulWidget {
  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  BottomNavigationBarType _type = BottomNavigationBarType.fixed;
  List<NavigationIconView> _navigationViews;
  BackupWorker backupWorker;

  startBackup(AppState state) {
    backupWorker = BackupWorker(state.apis);

    // start autoBackup
    if (state.config.autoBackup == true) {
      backupWorker.start();
    }
  }

  checkIntent() async {
    final platform = const MethodChannel('app.channel.shared.data');
    String filePath = await platform.invokeMethod("getSharedFile");
    print('filePath: $filePath');
  }

  @override
  void initState() {
    super.initState();

    // Intended for applications with a dark background.
    // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    _navigationViews = <NavigationIconView>[
      NavigationIconView(
        icon: Icon(Icons.folder_open),
        activeIcon: Icon(Icons.folder),
        title: '云盘',
        nav: 'files',
        view: () => Files(
            node: Node(tag: 'home', location: 'home'),
            fileNavViews: fileNavViews),
        color: Colors.teal,
      ),
      NavigationIconView(
        activeIcon: Icon(Icons.photo_library),
        icon: Icon(OMIcons.photoLibrary),
        title: '相簿',
        nav: 'photos',
        view: () => Photos(backupWorker: backupWorker),
        color: Colors.indigo,
      ),
      NavigationIconView(
        activeIcon: const Icon(Icons.router),
        icon: const Icon(OMIcons.router),
        title: '设备',
        nav: 'device',
        view: () => MyStation(),
        color: Colors.deepPurple,
      ),
      NavigationIconView(
        activeIcon: const Icon(Icons.person),
        icon: const Icon(Icons.person_outline),
        title: '我的',
        nav: 'user',
        view: () => AccountInfo(),
        color: Colors.deepOrange,
      ),
    ];

    checkIntent();
  }

  @override
  void dispose() {
    super.dispose();
    backupWorker?.abort();
  }

  @override
  Widget build(BuildContext context) {
    final BottomNavigationBar botNavBar = BottomNavigationBar(
      items: _navigationViews
          .map<BottomNavigationBarItem>(
              (NavigationIconView navigationView) => navigationView.item)
          .toList(),
      currentIndex: _currentIndex,
      type: _type,
      onTap: (int index) {
        setState(() {
          _currentIndex = index;
        });
      },
    );
    return StoreConnector<AppState, AppState>(
      onInit: (store) => startBackup(store.state),
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Scaffold(
          body: Center(child: _navigationViews[_currentIndex].view()),
          bottomNavigationBar: botNavBar,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import '../files/file.dart';
import '../device/station.dart';
import '../redux/redux.dart';

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

class BottomNavigation extends StatefulWidget {
  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  BottomNavigationBarType _type = BottomNavigationBarType.fixed;
  List<NavigationIconView> _navigationViews;

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
        view: () => Files(node: Node(tag: 'home')),
        color: Colors.teal,
      ),
      NavigationIconView(
        activeIcon: Icon(Icons.photo_library),
        icon: Icon(OMIcons.photoLibrary),
        title: '相簿',
        nav: 'photos',
        view: () => CircularProgressIndicator(backgroundColor: Colors.indigo),
        color: Colors.indigo,
      ),
      NavigationIconView(
        activeIcon: const Icon(Icons.router),
        icon: const Icon(OMIcons.router),
        title: '设备',
        nav: 'device',
        view: () => Station(),
        color: Colors.deepPurple,
      ),
      NavigationIconView(
        activeIcon: const Icon(Icons.person),
        icon: const Icon(Icons.person_outline),
        title: '我的',
        nav: 'user',
        view: () =>
            CircularProgressIndicator(backgroundColor: Colors.deepOrange),
        color: Colors.deepOrange,
      ),
    ];
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

    return Scaffold(
      body: Center(child: _navigationViews[_currentIndex].view()),
      bottomNavigationBar: botNavBar,
    );
  }
}

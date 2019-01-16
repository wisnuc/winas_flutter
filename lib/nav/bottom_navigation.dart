import 'package:flutter/material.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import '../files/file.dart';

class NavigationIconView {
  NavigationIconView({
    Widget icon,
    Widget activeIcon,
    Widget view,
    String title,
    String nav,
    Color color,
    TickerProvider vsync,
  })  : _view = view,
        item = BottomNavigationBarItem(
          icon: icon,
          activeIcon: activeIcon,
          title: Text(title),
          backgroundColor: color,
        ),
        controller = AnimationController(
          // duration: Duration(milliseconds: 2000),
          duration: kThemeAnimationDuration,
          vsync: vsync,
        ) {
    _animation = controller.drive(
      CurveTween(
        curve: const Interval(0.5, 1.0, curve: Curves.fastOutSlowIn),
      ),
    );
  }
  final Widget _view;
  final BottomNavigationBarItem item;
  final AnimationController controller;
  Animation<double> _animation;

  FadeTransition transition(
    BottomNavigationBarType type,
    BuildContext context,
  ) {
    // Color iconColor;
    // if (type == BottomNavigationBarType.shifting) {
    //   iconColor = _color;
    // } else {
    //   final ThemeData themeData = Theme.of(context);
    //   iconColor = themeData.brightness == Brightness.light
    //       ? themeData.primaryColor
    //       : themeData.accentColor;
    // }

    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: _animation.drive(
          Tween<Offset>(
            begin: const Offset(0.0, 0.02), // Slightly down.
            end: Offset.zero,
          ),
        ),
        child: Center(
          child: _view,
        ),
      ),
    );
  }
}

class BottomNavigation extends StatefulWidget {
  @override
  _BottomNavigationState createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  BottomNavigationBarType _type = BottomNavigationBarType.shifting;
  List<NavigationIconView> _navigationViews;

  @override
  void initState() {
    super.initState();
    _navigationViews = <NavigationIconView>[
      NavigationIconView(
        icon: Icon(Icons.folder_open),
        activeIcon: Icon(Icons.folder),
        title: '云盘',
        nav: 'files',
        view: Files(),
        color: Colors.teal,
        vsync: this,
      ),
      NavigationIconView(
        activeIcon: Icon(Icons.photo_library),
        icon: Icon(OMIcons.photoLibrary),
        title: '相簿',
        nav: 'photos',
        view: CircularProgressIndicator(backgroundColor: Colors.indigo),
        color: Colors.indigo,
        vsync: this,
      ),
      NavigationIconView(
        activeIcon: const Icon(Icons.router),
        icon: const Icon(OMIcons.router),
        title: '设备',
        nav: 'device',
        view: CircularProgressIndicator(backgroundColor: Colors.deepPurple),
        color: Colors.deepPurple,
        vsync: this,
      ),
      NavigationIconView(
        activeIcon: const Icon(Icons.person),
        icon: const Icon(Icons.person_outline),
        title: '我的',
        nav: 'user',
        view: CircularProgressIndicator(backgroundColor: Colors.deepOrange),
        color: Colors.deepOrange,
        vsync: this,
      ),
    ];

    _navigationViews[_currentIndex].controller.value = 1.0;
  }

  @override
  void dispose() {
    for (NavigationIconView view in _navigationViews) view.controller.dispose();
    super.dispose();
  }

  Widget _buildTransitionsStack() {
    final List<FadeTransition> transitions = <FadeTransition>[];

    for (NavigationIconView view in _navigationViews) {
      transitions.add(view.transition(_type, context));
    }

    // We want to have the newly animating (fading in) views on top.
    transitions.sort((FadeTransition a, FadeTransition b) {
      final Animation<double> aAnimation = a.opacity;
      final Animation<double> bAnimation = b.opacity;
      final double aValue = aAnimation.value;
      final double bValue = bAnimation.value;
      return aValue.compareTo(bValue);
    });

    return Stack(children: transitions);
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
          _navigationViews[_currentIndex].controller.reverse();
          _currentIndex = index;
          _navigationViews[_currentIndex].controller.forward();
        });
      },
    );

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Bottom navigation'),
      //   actions: <Widget>[
      //     PopupMenuButton<BottomNavigationBarType>(
      //       onSelected: (BottomNavigationBarType value) {
      //         setState(() {
      //           _type = value;
      //         });
      //       },
      //       itemBuilder: (BuildContext context) =>
      //           <PopupMenuItem<BottomNavigationBarType>>[
      //             const PopupMenuItem<BottomNavigationBarType>(
      //               value: BottomNavigationBarType.fixed,
      //               child: Text('Fixed'),
      //             ),
      //             const PopupMenuItem<BottomNavigationBarType>(
      //               value: BottomNavigationBarType.shifting,
      //               child: Text('Shifting'),
      //             )
      //           ],
      //     )
      //   ],
      // ),
      body: Center(child: _buildTransitionsStack()),
      bottomNavigationBar: botNavBar,
    );
  }
}

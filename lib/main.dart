import 'package:flutter/material.dart';
import './login/login.dart';
import './nav/bottom_navigation.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primaryColor: Colors.teal,
        accentColor: Colors.redAccent,
      ),
      routes: <String, WidgetBuilder>{
        '/login': (BuildContext context) => new LoginPage(),
        '/station': (BuildContext context) => new BottomNavigation(),
      },
      home: BottomNavigation(),
    );
  }
}

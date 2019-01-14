import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.0,
        backgroundColor: Colors.teal[700], // no shadow
        actions: <Widget>[
          FlatButton(
            child: Text("登录"),
            textColor: Colors.white,
            onPressed: () => {},
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints.expand(),
          padding: EdgeInsets.all(16),
          color: Colors.teal[700],
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('欢迎使用闻上云盘',
                  style: TextStyle(fontSize: 28.0, color: Colors.white),
                  textAlign: TextAlign.left),
              Container(height: 48.0),
              SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: Stack(children: [
                    SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: FlatButton(
                          color: Colors.white,
                          // icon: Icon(Icons.album, color: Colors.teal[700]),
                          child: Text(
                            "使用微信登录注册",
                            style: TextStyle(
                                color: Colors.teal[700], fontSize: 16),
                          ),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0)),
                          onPressed: () => {},
                        )),
                    Positioned(
                      child: Icon(Icons.album, color: Colors.teal[700]),
                      left: 16,
                      top: 8,
                    )
                  ])),
              Container(height: 16.0),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlineButton(
                  color: Colors.teal[700],
                  child: Text(
                    "创建账号",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20.0)),
                  onPressed: () => {},
                ),
              ),
              Container(height: 32.0),
              Text('点击继续、创建账号即表明同意闻上云盘的产品使用协议隐私政策',
                  style: TextStyle(fontSize: 12.0, color: Colors.white),
                  textAlign: TextAlign.left),
              Container(height: 48.0),
            ],
          ),
        ),
      ),
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   MyHomePage({Key key, this.title}) : super(key: key);

//   final String title;

//   @override
//   _MyHomePageState createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.display1,
//             ),
//             FlatButton(
//               child: Text("open new route"),
//               textColor: Colors.blue,
//               onPressed: () {
//                 // Navigator to new router
//                 Navigator.push(context,
//                     new MaterialPageRoute(builder: (context) {
//                   return new NewRoute();
//                 }));
//               },
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: Icon(Icons.add),
//       ),
//     );
//   }
// }

class NewRoute extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("New route"),
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints.expand(),
        child: Stack(
          alignment: Alignment.center, //指定未定位或部分定位widget的对齐方式
          children: <Widget>[
            Container(
              child: Text("Hello world", style: TextStyle(color: Colors.white)),
              color: Colors.red,
            ),
            Positioned(
              left: 18.0,
              child: Text("I am Jack"),
            ),
            Positioned(
              top: 18.0,
              child: Text("Your friend"),
            )
          ],
        ),
      ),
    );
  }
}

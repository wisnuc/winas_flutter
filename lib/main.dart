import 'dart:io';
import 'package:redux/redux.dart';
import 'package:flutter/material.dart';
import 'package:redux_persist/redux_persist.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:path_provider/path_provider.dart';
import './login/login.dart';
import './nav/bottom_navigation.dart';
import './redux/redux.dart';
import './transfer/manager.dart';
import './login/stationList.dart';

void main() async {
  Directory root = await getApplicationDocumentsDirectory();
  String _rootDir = root.path;

  // init persistor
  final persistor = Persistor<AppState>(
    storage: FileStorage(File("$_rootDir/config_v1.json")),
    serializer: JsonSerializer<AppState>(AppState.fromJson),
  );

  // Load initial state
  AppState initialState;

  // initialState = await persistor.load();
  try {
    initialState = await persistor.load(); // AppState.initial(); //
  } catch (error) {
    print('load initialState error: $error');
    initialState = AppState.initial();
  }
  if (initialState?.localUser?.uuid != null) {
    // init TransferManager, load TransferItem
    TransferManager.init(initialState.localUser.uuid).catchError(print);
  }
  // Create Store with Persistor middleware
  final store = Store<AppState>(
    appReducer,
    initialState: initialState ?? AppState.initial(),
    middleware: [persistor.createMiddleware()],
  );

  runApp(MyApp(initialState, store));
}

class MyApp extends StatelessWidget {
  final Store<AppState> store;
  final AppState initialState;

  MyApp(this.initialState, this.store);

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: MaterialApp(
        title: 'Winas App',
        theme: ThemeData(
          primaryColor: Colors.teal,
          accentColor: Colors.redAccent,
          iconTheme: IconThemeData(color: Colors.black38),
        ),
        routes: <String, WidgetBuilder>{
          '/login': (BuildContext context) => LoginPage(),
          '/station': (BuildContext context) => BottomNavigation(),
          // log out device, then jump to device list
          '/deviceList': (BuildContext context) {
            // cancel monitor of network connection
            store.state?.apis?.monitorCancel();
            // remove apis, device, reset config
            store.dispatch(UpdateApisAction(null));
            store.dispatch(DeviceLoginAction(null));
            store.dispatch(UpdateConfigAction(Config()));
            print('afterLogout ${store.state}');
            return StationList(
              request: store.state.cloud,
              afterLogout: true,
            );
          },
        },
        home: (store?.state?.account?.id != null && store?.state?.apis != null)
            ? BottomNavigation()
            : LoginPage(),
      ),
    );
  }
}

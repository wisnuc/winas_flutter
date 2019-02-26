import 'package:flutter_redux/flutter_redux.dart';
import 'package:flutter/material.dart';
import '../redux/redux.dart';

class NewDeviceName extends StatefulWidget {
  NewDeviceName({Key key, this.deviceName}) : super(key: key);
  final String deviceName;
  @override
  _NewDeviceNameState createState() => _NewDeviceNameState();
}

class _NewDeviceNameState extends State<NewDeviceName> {
  String _newName;
  String _error;
  bool loading = false;

  _onPressed(context, store) async {
    AppState state = store.state;
    Device device = state.device;

    print(_newName);

    setState(() {
      loading = true;
    });
    String deviceSN = device.deviceSN;
    try {
      await state.cloud.req('renameStation', {
        'deviceSN': deviceSN,
        'name': _newName,
      });
      // update StatinData
      store.dispatch(
        DeviceLoginAction(
          Device(
            deviceSN: deviceSN,
            deviceName: _newName,
            lanIp: device.lanIp,
            lanToken: device.lanToken,
          ),
        ),
      );
    } catch (error) {
      print(error.response.data);
      setState(() {
        loading = false;
        _error = '重命名失败';
      });
      return;
    }

    Navigator.pop(context, true);
  }

  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _newName = widget.deviceName;
    _controller = TextEditingController(text: _newName);
  }

  @override
  Widget build(BuildContext context) {
    bool disabled =
        loading || _newName == null || _newName == widget.deviceName;
    return StoreConnector<AppState, AppState>(
      onInit: (store) => {},
      onDispose: (store) => {},
      converter: (store) => store.state,
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            elevation: 0.0, // no shadow
            backgroundColor: Colors.white10,
            brightness: Brightness.light,
            iconTheme: IconThemeData(color: Colors.black38),
          ),
          body: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    key: Key('account'),
                    onChanged: (text) {
                      setState(() {
                        _error = null;
                        _newName = text;
                      });
                    },
                    decoration: InputDecoration(errorText: _error),
                    controller: _controller,
                    autofocus: true,
                    style: TextStyle(fontSize: 28, color: Colors.black87),
                  ),
                ),
                Container(height: 32),
                Center(
                  child: loading ? CircularProgressIndicator() : Container(),
                ),
              ],
            ),
          ),
          floatingActionButton: Builder(
            builder: (ctx) {
              return StoreConnector<AppState, VoidCallback>(
                converter: (store) => () => _onPressed(ctx, store),
                builder: (context, callback) => FloatingActionButton(
                      onPressed: disabled ? null : callback,
                      tooltip: '确定',
                      backgroundColor: disabled ? Colors.grey : Colors.teal,
                      elevation: 0.0,
                      child: Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
              );
            },
          ),
        );
      },
    );
  }
}

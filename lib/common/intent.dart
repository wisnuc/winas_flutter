import 'dart:async';
import 'package:flutter/services.dart';

class Intent {
  static MethodChannel initChannel = MethodChannel('app.channel.intent/init');
  static EventChannel newIntentChannel = EventChannel('app.channel.intent/new');

  static Stream<String> newIntentStream;

  static Stream<String> listenToOnNewIntent() {
    if (newIntentStream == null)
      newIntentStream =
          newIntentChannel.receiveBroadcastStream().cast<String>();
    return newIntentStream;
  }

  static Future<String> get initIntent async {
    String filePath;
    try {
      filePath = await initChannel.invokeMethod('getSharedFile');
    } catch (e) {
      print(e);
      filePath = null;
    }

    return filePath;
  }
}

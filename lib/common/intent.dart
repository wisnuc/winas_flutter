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
    final String filePath = await initChannel.invokeMethod('getSharedFile');
    return filePath;
  }
}

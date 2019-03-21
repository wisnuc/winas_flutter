package com.wisnuc.winas;

import android.content.Intent;
import android.os.Bundle;
import android.net.Uri;

import java.net.URI;
import java.nio.ByteBuffer;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.ActivityLifecycleListener;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {

  private String sharedFile;

  @Override
  protected void onCreate(Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);
    Intent intent = getIntent();
    String action = intent.getAction();
    String type = intent.getType();

    if (Intent.ACTION_SEND.equals(action) && type != null) {
      handleSendData(intent);
    }

    new MethodChannel(getFlutterView(), "app.channel.shared.data").setMethodCallHandler(new MethodCallHandler() {
      @Override
      public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if (call.method.contentEquals("getSharedFile")) {
          result.success(sharedFile);
          sharedFile = null;
        }
      }
    });
  }

  void handleSendData(Intent intent) {
    Uri uri = (Uri) getIntent().getExtras().get("android.intent.extra.STREAM");
    String path = uri.getPath();
    sharedFile = path;
  }
}

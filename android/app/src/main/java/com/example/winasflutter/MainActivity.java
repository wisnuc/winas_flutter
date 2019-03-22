package com.wisnuc.winas;

import android.net.Uri;
import android.os.Bundle;
import android.content.Intent;

import java.io.File;
import java.nio.ByteBuffer;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.ActivityLifecycleListener;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FlutterActivity {

  public static final String TAG = "eventchannel";
  private String sharedFile;
  private EventChannel.EventSink channelEvents;

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

    new MethodChannel(getFlutterView(), "app.channel.intent/init").setMethodCallHandler(new MethodCallHandler() {
      @Override
      public void onMethodCall(MethodCall call, MethodChannel.Result result) {
        if (call.method.contentEquals("getSharedFile")) {
          result.success(sharedFile);
          sharedFile = null;
        }
      }
    });

    new EventChannel(getFlutterView(), "app.channel.intent/new").setStreamHandler(new EventChannel.StreamHandler() {
      @Override
      public void onListen(Object args, EventChannel.EventSink events) {
        channelEvents = events;
      }

      @Override
      public void onCancel(Object args) {
        channelEvents = null;
      }
    });
  }

  @Override
  protected void onNewIntent(Intent intent) {
    super.onNewIntent(intent);
    String action = intent.getAction();
    String type = intent.getType();
    if (Intent.ACTION_SEND.equals(action) && type != null) {
      Uri uri = (Uri) intent.getExtras().get("android.intent.extra.STREAM");
      System.out.println("init Intent>>>>>>>>>>>>>>>>>>");
      System.out.println(uri);
      if (channelEvents != null) {
        channelEvents.success(uri.toString());
      }
    }
  }

  void handleSendData(Intent intent) {
    Uri uri = (Uri) intent.getExtras().get("android.intent.extra.STREAM");
    System.out.println("new Intent>>>>>>>>>>>>>>>>>>");
    System.out.println(uri);
    sharedFile = uri.toString();
  }
}

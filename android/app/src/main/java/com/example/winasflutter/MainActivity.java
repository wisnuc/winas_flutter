package com.wisnuc.winas;

import android.net.Uri;
import android.os.Bundle;
import android.content.Intent;

import java.io.File;
import java.util.Random;
import java.nio.ByteBuffer;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.Array;
import java.io.FileOutputStream;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.ActivityLifecycleListener;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugins.GeneratedPluginRegistrant;
import io.flutter.util.PathUtils;

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
      sharedFile = handleSendData(intent);
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
      String filePath = handleSendData(intent);
      if (channelEvents != null && filePath != null) {
        channelEvents.success(filePath);
      }
    }
  }

  private String handleSendData(Intent intent) {
    Uri uri = (Uri) intent.getExtras().get("android.intent.extra.STREAM");
    System.out.println("new Intent>>>>>>>>>>>>>>>>>>");
    System.out.println(uri);

    // get fileName
    String path = uri.getPath();
    String arr[] = path.split("/");
    String fileName = arr[arr.length - 1];

    // get homeDir path and tmpFile path
    String homeDir = getPathProviderApplicationDocumentsDirectory();
    final int random = new Random().nextInt(100000);
    String saveDirPath = homeDir + File.separator + "trans" + File.separator + String.valueOf(random);
    String tmpFilePath = saveDirPath + File.separator + fileName;

    // copy file >>>>>>>>>>>>>>>>>>>>>>
    byte buffer[] = new byte[1024];
    int length = 0;
    try {
      File dir = new File(saveDirPath);
      dir.mkdirs();
      File f = new File(tmpFilePath);
      f.setWritable(true, false);
      OutputStream outputStream = new FileOutputStream(f);

      InputStream inputStream = getContentResolver().openInputStream(uri);
      while ((length = inputStream.read(buffer)) > 0) {
        outputStream.write(buffer, 0, length);
      }
      outputStream.close();
      inputStream.close();
    } catch (Exception e) {
      System.out.println("handle intent file error !!!");
      System.out.println(e.getMessage());
      tmpFilePath = null;
    }

    System.out.println("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<tmpFile Path>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
    System.out.println(tmpFilePath);
    return tmpFilePath;

  }

  private String getPathProviderApplicationDocumentsDirectory() {
    return PathUtils.getDataDirectory(this);
  }
}

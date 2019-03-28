#include "AppDelegate.h"
#include "GeneratedPluginRegistrant.h"
#import <WXApi.h>
#import <FluwxResponseHandler.h>
#import <Flutter/Flutter.h>

@implementation AppDelegate{
    FlutterEventSink _eventSink;
    NSString * _filePath;
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  // Override point for customization after application launch.
  FlutterEventChannel * eventChannel = [FlutterEventChannel eventChannelWithName:@"app.channel.intent/new" binaryMessenger:(FlutterViewController *)self.window.rootViewController];
  [eventChannel setStreamHandler:self];
    
    FlutterMethodChannel* mChannel = [FlutterMethodChannel
                                            methodChannelWithName:@"app.channel.intent/init"
                                            binaryMessenger:(FlutterViewController *)self.window.rootViewController];
    [mChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        result(_filePath);
        _filePath = nil;
    }];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [self handleShareFile:url];
    return [WXApi handleOpenURL:url delegate:[FluwxResponseHandler defaultManager]];
}
// NOTE: 9.0以后使用新API接口
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
    [self handleShareFile:url];
    return [WXApi handleOpenURL:url delegate:[FluwxResponseHandler defaultManager]];
}


-(void)handleShareFile:(NSURL *)url {
    if (url != nil && [url isFileURL]) {
        NSString *fileName = url.lastPathComponent;
        NSString *documentDir = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *copydir = [documentDir stringByAppendingPathComponent:[NSString stringWithFormat:@"trans/%@", [self createUUID]]];
        if (![[NSFileManager defaultManager] fileExistsAtPath:copydir]) {
            // create dir
            [[NSFileManager defaultManager] createDirectoryAtPath:copydir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSString *copyPath = [copydir stringByAppendingPathComponent:fileName];
        
        if([[NSFileManager defaultManager] moveItemAtURL:url toURL:[NSURL fileURLWithPath:copyPath] error:nil]){
            if (_eventSink)_eventSink(copyPath);
            else _filePath = copyPath;
        }
    }
}

- (NSString *)createUUID{
    NSString *  result;
    CFUUIDRef   uuid;
    CFStringRef uuidStr;
    uuid = CFUUIDCreate(NULL);
    uuidStr = CFUUIDCreateString(NULL, uuid);
    result =[NSString stringWithFormat:@"%@", uuidStr];
    CFRelease(uuidStr);
    CFRelease(uuid);
    return result;
}

- (FlutterError*)onListenWithArguments:(id)arguments
                             eventSink:(FlutterEventSink)eventSink {
    _eventSink = eventSink;
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    _eventSink = nil;
    return nil;
}

@end

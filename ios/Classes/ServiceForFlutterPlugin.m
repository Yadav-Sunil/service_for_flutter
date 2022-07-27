#import "ServiceForFlutterPlugin.h"
#if __has_include(<service_for_flutter/service_for_flutter-Swift.h>)
#import <service_for_flutter/service_for_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "service_for_flutter-Swift.h"
#endif

@implementation ServiceForFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftServiceForFlutterPlugin registerWithRegistrar:registrar];
}
@end

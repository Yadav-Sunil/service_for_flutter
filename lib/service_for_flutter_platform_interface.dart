import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'configs.dart';
import 'service_for_flutter_method_channel.dart';

abstract class Observable {
  void invoke(String method, [Map<String, dynamic>? args]);
  Stream<Map<String, dynamic>?> on(String method);
}

abstract class ServiceForFlutterPlatform  extends PlatformInterface implements Observable {
  /// Constructs a ServiceForFlutterPlatform.
  ServiceForFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static ServiceForFlutterPlatform _instance = MethodChannelServiceForFlutter();

  /// The default instance of [ServiceForFlutterPlatform] to use.
  ///
  /// Defaults to [MethodChannelServiceForFlutter].
  static ServiceForFlutterPlatform get instance => _instance;
  
  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ServiceForFlutterPlatform] when
  /// they register themselves.
  static set instance(ServiceForFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> configure({
    required IosConfiguration iosConfiguration,
    required AndroidConfiguration androidConfiguration,
  });

  Future<bool> start();

  Future<bool> isServiceRunning();
}

abstract class ServiceInstance implements Observable {
  /// Stop the service
  Future<void> stopSelf();
}

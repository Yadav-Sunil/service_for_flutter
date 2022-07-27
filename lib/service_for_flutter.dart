
import 'configs.dart';
import 'service_for_flutter_platform_interface.dart';

class ServiceForFlutter  implements Observable {
  ServiceForFlutterPlatform get _platform => ServiceForFlutterPlatform.instance;

  Future<bool> configure({
    required IosConfiguration iosConfiguration,
    required AndroidConfiguration androidConfiguration,
  }) =>
      _platform.configure(
        iosConfiguration: iosConfiguration,
        androidConfiguration: androidConfiguration,
      );

  static final ServiceForFlutter _instance = ServiceForFlutter._internal();

  ServiceForFlutter._internal();

  factory ServiceForFlutter() => _instance;

  /// Starts the background service.
  Future<bool> startService() => _platform.start();

  /// Whether the service is running
  Future<bool> isRunning() => _platform.isServiceRunning();

  @override
  void invoke(String method, [Map<String, dynamic>? arg]) =>
      _platform.invoke(method, arg);

  @override
  Stream<Map<String, dynamic>?> on(String method) => _platform.on(method);
}

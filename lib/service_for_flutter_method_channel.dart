import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'configs.dart';
import 'service_for_flutter_platform_interface.dart';


@pragma('vm:entry-point')
Future<void> _entrypoint() async {
  WidgetsFlutterBinding.ensureInitialized();
  final service = AndroidServiceInstance._();
  final int handle = await service._getHandler();
  final callbackHandle = CallbackHandle.fromRawHandle(handle);
  final onStart = PluginUtilities.getCallbackFromHandle(callbackHandle);
  if (onStart != null) {
    onStart(service);
  }
}

/// An implementation of [ServiceForFlutterPlatform] that uses method channels.
class MethodChannelServiceForFlutter extends ServiceForFlutterPlatform {

  /// The method channel used to interact with the native platform.
  /// Registers this class as the default instance of [FlutterBackgroundServicePlatform].
  static void registerWith() {
    ServiceForFlutterPlatform.instance = ServiceForFlutterPlatform.instance;
  }

  static const  _channel = MethodChannel(
    'id.flutter/service_for_flutter_android',
    JSONMethodCodec(),
  );

  @override
  Future<bool> configure({
    required IosConfiguration iosConfiguration,
    required AndroidConfiguration androidConfiguration,
  }) async {
    _channel.setMethodCallHandler(_handle);

    final CallbackHandle? entryPointHandle =
    PluginUtilities.getCallbackHandle(_entrypoint);

    final CallbackHandle? handle =
    PluginUtilities.getCallbackHandle(androidConfiguration.onStart);

    if (entryPointHandle == null || handle == null) {
      return false;
    }

    final result = await _channel.invokeMethod(
      "configure",
      {
        "entrypoint_handle": entryPointHandle.toRawHandle(),
        "background_handle": handle.toRawHandle(),
        "is_foreground_mode": androidConfiguration.isForegroundMode,
        "auto_start_on_boot": androidConfiguration.autoStart,
      },
    );

    return result ?? false;
  }

  @override
  Future<bool> isServiceRunning() async {
    var result = await _channel.invokeMethod("isServiceRunning");
    return result ?? false;
  }

  final _controller = StreamController.broadcast(sync: true);

  void dispose() {
    _controller.close();
  }

  Future<dynamic> _handle(MethodCall call) async {
    switch (call.method) {
      case "onReceiveData":
        _controller.sink.add(call.arguments);
        break;
      default:
    }

    return true;
  }

  @override
  Future<bool> start() async {
    final result = await _channel.invokeMethod('start');
    return result ?? false;
  }

  @override
  void invoke(String method, [Map<String, dynamic>? args]) {
    _channel.invokeMethod("sendData", {
      'method': method,
      'args': args,
    });
  }

  @override
  Stream<Map<String, dynamic>?> on(String method) {
    return _controller.stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          if (data['method'] == method) {
            sink.add(data['args']);
          }
        },
      ),
    );
  }
}

class AndroidServiceInstance extends ServiceInstance {
  static const MethodChannel _channel = MethodChannel(
    'id.flutter/service_for_flutter_android_bg',
    JSONMethodCodec(),
  );

  AndroidServiceInstance._() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final _controller = StreamController.broadcast(sync: true);

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case "onReceiveData":
        _controller.sink.add(call.arguments);
        break;
      default:
    }
  }

  @override
  void invoke(String method, [Map<String, dynamic>? args]) {
    _channel.invokeMethod('sendData', {
      'method': method,
      'args': args,
    });
  }

  @override
  Future<void> stopSelf() async {
    await _channel.invokeMethod("stopService");
  }


  @override
  Stream<Map<String, dynamic>?> on(String method) {
    return _controller.stream.transform(
      StreamTransformer.fromHandlers(
        handleData: (data, sink) {
          if (data['method'] == method) {
            sink.add(data['args']);
          }
        },
      ),
    );
  }

  Future<void> setForegroundNotificationInfo({
    required String title,
    required String content,
  }) async {
    await _channel.invokeMethod("setNotificationInfo", {
      "title": title,
      "content": content,
    });
  }

  Future<void> setAsForegroundService() async {
    await _channel.invokeMethod("setForegroundMode", {
      'value': true,
    });
  }

  Future<void> setAsBackgroundService() async {
    await _channel.invokeMethod("setForegroundMode", {
      'value': false,
    });
  }

  Future<int> _getHandler() async {
    return await _channel.invokeMethod('getHandler');
  }

  Future<void> setAutoStartOnBootMode(bool value) async {
    await _channel.invokeMethod("setAutoStartOnBootMode", {
      "value": value,
    });
  }
}

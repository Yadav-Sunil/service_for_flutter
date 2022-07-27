import 'dart:async';

import 'service_for_flutter_platform_interface.dart';


class IosConfiguration {
  /// must be a top level or static method
  /// this method will be executed when app is in foreground
  final Function(ServiceInstance service) onForeground;

  /// must be a top level or static method
  /// this method will be executed by background fetch
  /// make sure you don't execute long running task there because of limitations on ios
  /// recommended maximum executed duration is only 15-20 seconds.
  final FutureOr<bool> Function(ServiceInstance service) onBackground;

  /// whether service auto start after configure.
  final bool autoStart;

  IosConfiguration({
    required this.onForeground,
    required this.onBackground,
    this.autoStart = true,
  });
}

class AndroidConfiguration {
  /// must be a top level or static method
  final Function(ServiceInstance service) onStart;

  /// whether service can start automatically on boot and after configure
  final bool autoStart;

  /// whether service is foreground or background mode
  final bool isForegroundMode;

  final String? foregroundServiceNotificationTitle;
  final String? foregroundServiceNotificationContent;

  AndroidConfiguration({
    required this.onStart,
    this.autoStart = true,
    required this.isForegroundMode,
    this.foregroundServiceNotificationContent,
    this.foregroundServiceNotificationTitle,
  });
}

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:service_for_flutter/configs.dart';
import 'package:service_for_flutter/service_for_flutter.dart';
import 'package:service_for_flutter/service_for_flutter_method_channel.dart';
import 'package:service_for_flutter/service_for_flutter_platform_interface.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();
  runApp(const MyApp());
}

Future<void> initializeService() async {
  final service = ServiceForFlutter();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      // this will be executed when app is in foreground or background in separated isolate
      onStart: onStart,

      // auto start service
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(
      // auto start service
      autoStart: true,

      // this will be executed when app is in foreground in separated isolate
      onForeground: onStart,

      // you have to enable background fetch capability on xcode project
      onBackground: onIosBackground,
    ),
  );
  service.startService();
}

// to ensure this is executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  print('FLUTTER BACKGROUND FETCH');

  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to version 3.0.0
  // We have to register the plugin manually

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // bring to foreground
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: "My App Service",
        content:
            "Updated at ${DateTime.now()}",
      );
    }

    /// you can see this log in logcat
    print(
        'FLUTTER BACKGROUND SERVICE: ${DateTime.now()}');
    if (service is AndroidServiceInstance) {
      service.invoke(
        'update',
        {
          "current_date": DateTime.now().toIso8601String(),
          "device": "",
        },
      );
    }
  });
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String text = "Stop Service";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Service App'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Map<String, dynamic>?>(
                stream: ServiceForFlutter().on('update'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final data = snapshot.data!;
                  String? device = data["device"];
                  DateTime? date = DateTime.tryParse(data["current_date"]);
                  return Column(
                    children: [
                      Text(device ?? 'Unknown'),
                      Text(date.toString()),
                    ],
                  );
                },
              ),
              ElevatedButton(
                child: const Text("Foreground Mode"),
                onPressed: () {
                  ServiceForFlutter().invoke("setAsForeground");
                },
              ),
              ElevatedButton(
                child: const Text("Background Mode"),
                onPressed: () {
                  ServiceForFlutter().invoke("setAsBackground");
                },
              ),
              ElevatedButton(
                child: Text(text),
                onPressed: () async {
                  final service = ServiceForFlutter();
                  var isRunning = await service.isRunning();
                  if (isRunning) {
                    service.invoke("stopService");
                  } else {
                    service.startService();
                  }

                  if (!isRunning) {
                    text = 'Stop Service';
                  } else {
                    text = 'Start Service';
                  }
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

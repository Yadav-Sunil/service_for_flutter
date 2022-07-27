package com.service.service_for_flutter;

import static android.content.Context.MODE_PRIVATE;

import android.app.ActivityManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.service.ServiceAware;
import io.flutter.embedding.engine.plugins.service.ServicePluginBinding;
import io.flutter.plugin.common.JSONMethodCodec;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

//service_for_flutter

/**
 * ServiceForFlutterPlugin
 */
public class ServiceForFlutterPlugin implements FlutterPlugin, MethodCallHandler, ServiceAware {

    private static final String TAG = "FlutterServicePlugin";
    private static final List<ServiceForFlutterPlugin> _instances = new ArrayList<>();
    /// The MethodChannel that will the communication between Flutter and native Android
///
/// This local reference serves to register the plugin with the Flutter Engine and unregister it
/// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;
    private Context context;
    private BackgroundService service;

    public ServiceForFlutterPlugin() {
        _instances.add(this);
    }

    private static void configure(Context context, long entrypointHandle, long backgroundHandle, boolean isForeground, boolean autoStartOnBoot) {
        SharedPreferences pref = context.getSharedPreferences("id.flutter.service_for_flutter", MODE_PRIVATE);
        pref.edit()
                .putLong("entrypoint_handle", entrypointHandle)
                .putLong("background_handle", backgroundHandle)
                .putBoolean("is_foreground", isForeground)
                .putBoolean("auto_start_on_boot", autoStartOnBoot)
                .apply();
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        this.context = flutterPluginBinding.getApplicationContext();
        EventBus.getDefault().register(this);
//        LocalBroadcastManager localBroadcastManager = LocalBroadcastManager.getInstance(this.context);
//        localBroadcastManager.registerReceiver(this, new IntentFilter("id.flutter/service_for_flutter"));

//        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "service_for_flutter", JSONMethodCodec.INSTANCE);
//        channel.setMethodCallHandler(this);
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "id.flutter/service_for_flutter_android", JSONMethodCodec.INSTANCE);
        channel.setMethodCallHandler(this);
    }

    private void start() {
        BackgroundService.enqueue(context);
        boolean isForeground = BackgroundService.isForegroundService(context);
        Intent intent = new Intent(context, BackgroundService.class);
        if (isForeground) {
            ContextCompat.startForegroundService(context, intent);
        } else {
            context.startService(intent);
        }
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        String method = call.method;
        JSONObject arg = (JSONObject) call.arguments;

        try {
            if ("configure".equals(method)) {
                long entrypointHandle = arg.getLong("entrypoint_handle");
                long backgroundHandle = arg.getLong("background_handle");
                boolean isForeground = arg.getBoolean("is_foreground_mode");
                boolean autoStartOnBoot = arg.getBoolean("auto_start_on_boot");

                configure(context, entrypointHandle, backgroundHandle, isForeground, autoStartOnBoot);
                if (autoStartOnBoot) {
                    start();
                }

                result.success(true);
                return;
            }

            if ("start".equals(method)) {
                start();
                result.success(true);
                return;
            }

            if (method.equalsIgnoreCase("sendData")) {
                for (ServiceForFlutterPlugin plugin : _instances) {
                    if (plugin.service != null) {
                        plugin.service.receiveData((JSONObject) call.arguments);
                        Log.d(TAG, "sendData " + (JSONObject) call.arguments);
                        break;
                    }
                }

                result.success(true);
                return;
            }

            if (method.equalsIgnoreCase("isServiceRunning")) {
                result.success(isServiceRunning());
                return;
            }

            result.notImplemented();
        } catch (Exception e) {
            result.error("100", "Failed read arguments", null);
        }
    }

    private boolean isServiceRunning() {
        ActivityManager manager = (ActivityManager) context.getSystemService(Context.ACTIVITY_SERVICE);
        for (ActivityManager.RunningServiceInfo service : manager.getRunningServices(Integer.MAX_VALUE)) {
            if (BackgroundService.class.getName().equals(service.service.getClassName())) {
                return true;
            }
        }
        return false;
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
        EventBus.getDefault().unregister(this);
//        LocalBroadcastManager localBroadcastManager = LocalBroadcastManager.getInstance(this.context);
//        localBroadcastManager.unregisterReceiver(this);
    }

    @Subscribe(threadMode = ThreadMode.MAIN)
    public void onMessageEvent(MessageEvent event) {
        try {
            JSONObject jData = new JSONObject(event.message);
            if (channel != null) {
                channel.invokeMethod("onReceiveData", jData);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

//    @Override
//    public void onReceive(Context context, Intent intent) {
//        if (intent.getAction() == null) return;
//
//        if (intent.getAction().equalsIgnoreCase("id.flutter/service_for_flutter")) {
//            String data = intent.getStringExtra("data");
//            try {
//                JSONObject jData = new JSONObject(data);
//                if (channel != null) {
//                    channel.invokeMethod("onReceiveData", jData);
//                }
//            } catch (JSONException e) {
//                e.printStackTrace();
//            } catch (Exception e) {
//                e.printStackTrace();
//            }
//        }
//    }

    @Override
    public void onAttachedToService(@NonNull ServicePluginBinding binding) {
        Log.d(TAG, "onAttachedToService");

        this.service = (BackgroundService) binding.getService();
    }

    @Override
    public void onDetachedFromService() {
        this.service = null;
        Log.d(TAG, "onDetachedFromService");
    }
}




package com.service.service_for_flutter;

import static android.content.Context.MODE_PRIVATE;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

import androidx.core.content.ContextCompat;


public class BootReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        SharedPreferences pref = context.getSharedPreferences("id.flutter.service_for_flutter", MODE_PRIVATE);
        boolean autoStart = pref.getBoolean("auto_start_on_boot", true);
        if (autoStart) {
            if (BackgroundService.lockStatic == null) {
                BackgroundService.getLock(context).acquire(10 * 60 * 1000L /*10 minutes*/);
            }

            if (BackgroundService.isForegroundService(context)) {
                ContextCompat.startForegroundService(context, new Intent(context, BackgroundService.class));
            } else {
                context.startService(new Intent(context, BackgroundService.class));
            }
        }
    }
}

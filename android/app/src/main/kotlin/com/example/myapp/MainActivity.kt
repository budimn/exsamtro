package com.example.myapp

import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "exambro/lock"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "startLockTask" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        try {
                            activity.startLockTask()
                            result.success(null)
                        } catch (e: SecurityException) {
                            result.error("LOCK_TASK_FAILED", "Failed to start lock task: ${e.message}", null)
                        }
                    } else {
                        result.success(null) // Not supported on older versions
                    }
                }
                "stopLockTask" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                        try {
                            activity.stopLockTask()
                            result.success(null)
                        } catch (e: SecurityException) {
                           result.error("LOCK_TASK_FAILED", "Failed to stop lock task: ${e.message}", null)
                        }
                    } else {
                        result.success(null) // Not supported on older versions
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

package com.twinklywall.led_matrix_controller

import android.Manifest
import android.app.Activity
import android.app.ActivityManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.PixelFormat
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Binder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.view.SurfaceTexture
import android.view.TextureView
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.twinklywall.led_matrix_controller/screen_capture"
        private const val REQUEST_CODE = 100
        private const val SCREEN_RECORD_PERMISSION = 999
    }

    private val screenCaptureService = ScreenCaptureService()
    private lateinit var mediaProjectionManager: MediaProjectionManager
    private var mediaProjection: MediaProjection? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        mediaProjectionManager = getSystemService(MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startScreenCapture" -> {
                    if (checkPermissions()) {
                        startScreenCapture()
                        result.success(null)
                    } else {
                        requestPermissions()
                        result.error("PERMISSION_DENIED", "Screen capture permission not granted", null)
                    }
                }
                "stopScreenCapture" -> {
                    stopScreenCapture()
                    result.success(null)
                }
                "isCapturing" -> {
                    result.success(screenCaptureService.isCapturing)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun checkPermissions(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun requestPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.RECORD_AUDIO),
                SCREEN_RECORD_PERMISSION
            )
        }
    }

    private fun startScreenCapture() {
        val intent = mediaProjectionManager.createScreenCaptureIntent()
        startActivityForResult(intent, REQUEST_CODE)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                mediaProjection = mediaProjectionManager.getMediaProjection(resultCode, data)
                if (mediaProjection != null) {
                    screenCaptureService.startCapture(mediaProjection!!, this)
                }
            }
        }
    }

    private fun stopScreenCapture() {
        screenCaptureService.stopCapture()
        mediaProjection?.stop()
        mediaProjection = null
    }
}

@RequiresApi(Build.VERSION_CODES.LOLLIPOP)
class ScreenCaptureService : Service() {
    private inner class ScreenCaptureThread(
        private val mediaProjection: MediaProjection,
        private val context: Context
    ) : Thread(), TextureView.SurfaceTextureListener {
        private var surfaceTexture: SurfaceTexture? = null
        private var isRunning = true
        private val handler = Handler(Looper.getMainLooper())

        override fun run() {
            while (isRunning) {
                try {
                    captureFrame()
                    sleep(50) // 20 FPS
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }

        private fun captureFrame() {
            // Screen capture implementation
            // This would use MediaProjection's VirtualDisplay to capture frames
            // For now, we'll define the structure for the capturing mechanism
        }

        override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
            surfaceTexture = surface
        }

        override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {}
        override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean = false
        override fun onSurfaceTextureFrameAvailable(surface: SurfaceTexture) {}

        fun stop() {
            isRunning = false
        }
    }

    private var captureThread: ScreenCaptureThread? = null
    var isCapturing = false
        private set

    fun startCapture(mediaProjection: MediaProjection, context: Context) {
        if (!isCapturing) {
            captureThread = ScreenCaptureThread(mediaProjection, context)
            captureThread?.start()
            isCapturing = true
        }
    }

    fun stopCapture() {
        if (isCapturing) {
            captureThread?.stop()
            captureThread = null
            isCapturing = false
        }
    }

    override fun onBind(intent: Intent?): IBinder? = Binder()
}

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Screen capture service using FFmpeg x11grab (Linux) or GDI (Windows)
/// This is the PROFESSIONAL approach for continuous screen capture
/// NO sounds, NO popups, just raw pixel data from the display server
class ScreenCaptureService {
  static const platform = MethodChannel('com.twinklywall.led_matrix_controller/screen_capture');
  
  static bool _isCapturingDesktop = false;
  static Process? _ffmpegProcess;
  static bool _ffmpegAvailable = false;
  static bool _ffmpegChecked = false;

  /// Start capturing the screen
  static Future<bool> startCapture() async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('startScreenCapture');
        return true;
      } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        _isCapturingDesktop = true;
        debugPrint("[START] Desktop screen capture started");
        
        // Check if FFmpeg is available
        if (!_ffmpegChecked) {
          _ffmpegAvailable = await _checkFFmpeg();
          _ffmpegChecked = true;
        }
        
        return true;
      } else {
        debugPrint("[START] Screen capture not supported on ${Platform.operatingSystem}");
        return false;
      }
    } on PlatformException catch (e) {
      debugPrint("[START] Failed to start screen capture: '${e.message}'");
      return false;
    }
  }

  /// Check if FFmpeg is available
  static Future<bool> _checkFFmpeg() async {
    try {
      final result = await Process.run('ffmpeg', ['-version']);
      final available = result.exitCode == 0;
      debugPrint("[FFMPEG] Available: $available");
      if (available) {
        debugPrint("[FFMPEG] Version: ${result.stdout.toString().split('\n').first}");
      }
      return available;
    } catch (e) {
      debugPrint("[FFMPEG] Not found: $e");
      return false;
    }
  }

  /// Stop capturing the screen
  static Future<bool> stopCapture() async {
    try {
      if (Platform.isAndroid) {
        await platform.invokeMethod('stopScreenCapture');
        return true;
      } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        _isCapturingDesktop = false;
        debugPrint("[STOP] Desktop screen capture stopped");
        return true;
      }
      return false;
    } on PlatformException catch (e) {
      debugPrint("[STOP] Failed to stop screen capture: '${e.message}'");
      return false;
    }
  }

  /// Check if screen is currently being captured
  static Future<bool> isCapturing() async {
    try {
      if (Platform.isAndroid) {
        final bool result = await platform.invokeMethod('isCapturing');
        return result;
      } else if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        return _isCapturingDesktop;
      }
      return false;
    } on PlatformException catch (e) {
      debugPrint("[STATUS] Failed to check capture status: '${e.message}'");
      return false;
    }
  }

  /// Capture a single screenshot
  static Future<Uint8List?> captureScreenshot() async {
    final startTime = DateTime.now();
    debugPrint("[CAPTURE] ======== NEW FRAME ========");
    debugPrint("[CAPTURE] Starting at ${startTime.toIso8601String()}");
    
    try {
      if (Platform.isAndroid) {
        debugPrint("[CAPTURE] Using Android method channel");
        final result = await platform.invokeMethod('captureScreenshot');
        if (result is Uint8List) {
          debugPrint("[CAPTURE] Android returned ${result.length} bytes");
          return result;
        }
        debugPrint("[CAPTURE] Android returned null");
        return null;
      } else if (Platform.isLinux) {
        final result = await _captureScreenshotLinuxFFmpeg();
        final totalTime = DateTime.now().difference(startTime);
        debugPrint("[CAPTURE] Total frame time: ${totalTime.inMilliseconds}ms");
        return result;
      }
      return null;
    } on PlatformException catch (e) {
      debugPrint("[CAPTURE] PlatformException: ${e.message}");
      return null;
    } catch (e) {
      debugPrint("[CAPTURE] Unexpected error: $e");
      return null;
    }
  }

  /// Capture screenshot on Linux using FFmpeg x11grab
  /// This is MUCH better: direct access to X11 framebuffer, no sounds, no popups
  static Future<Uint8List?> _captureScreenshotLinuxFFmpeg() async {
    final captureStartTime = DateTime.now();
    debugPrint("[FFMPEG] Starting single frame capture");
    
    try {
      // Use FFmpeg to grab one frame from X11 display
      // -f x11grab = use X11 video input device
      // -video_size <display_size> = size of the display
      // -i :0.0 = X11 display :0.0
      // -frames:v 1 = capture only 1 frame
      // -f image2pipe = output to stdout as image
      // -vcodec png = encode as PNG
      // pipe:1 = write to stdout
      
      debugPrint("[FFMPEG] Running: ffmpeg -f x11grab -video_size 1920x1080 -i :0.0 -frames:v 1 -f image2pipe -vcodec png pipe:1");
      
      final result = await Process.run(
        'ffmpeg',
        [
          '-loglevel', 'quiet',        // Suppress FFmpeg output
          '-f', 'x11grab',             // X11 screen capture input
          '-video_size', '1920x1080',  // TODO: Auto-detect screen size
          '-i', ':0.0',                // X11 display :0.0
          '-frames:v', '1',            // Capture exactly 1 frame
          '-f', 'image2pipe',          // Output format: image to pipe
          '-vcodec', 'png',            // PNG codec
          'pipe:1'                     // Write to stdout
        ],
        stdoutEncoding: null, // Binary output
      );
      
      final captureDuration = DateTime.now().difference(captureStartTime);
      debugPrint("[FFMPEG] Capture took ${captureDuration.inMilliseconds}ms");
      
      if (result.exitCode != 0) {
        debugPrint("[FFMPEG] ERROR: Exit code ${result.exitCode}");
        if (result.stderr.toString().isNotEmpty) {
          debugPrint("[FFMPEG] Stderr: ${result.stderr}");
        }
        return null;
      }
      
      final imageBytes = result.stdout as Uint8List;
      debugPrint("[FFMPEG] Captured ${imageBytes.length} bytes");
      
      // Process the PNG data
      return await _processImageBytes(imageBytes);
    } catch (e, stackTrace) {
      debugPrint("[FFMPEG] Capture failed: $e");
      debugPrint("[FFMPEG] Stack trace: $stackTrace");
      return null;
    }
  }

  /// Process image bytes: decode, scale to 90x100, convert to RGB
  static Future<Uint8List?> _processImageBytes(Uint8List imageBytes) async {
    final processStartTime = DateTime.now();
    debugPrint("[PROCESS] Input: ${imageBytes.length} bytes");
    
    try {
      // Step 1: Decode image
      final decodeStartTime = DateTime.now();
      final image = img.decodeImage(imageBytes);
      final decodeDuration = DateTime.now().difference(decodeStartTime);
      debugPrint("[PROCESS] Decode: ${decodeDuration.inMilliseconds}ms");

      if (image == null) {
        debugPrint("[PROCESS] ERROR: Failed to decode image");
        return null;
      }
      debugPrint("[PROCESS] Original size: ${image.width}x${image.height}");

      // Step 2: Resize to 90x100
      final resizeStartTime = DateTime.now();
      final resized = img.copyResize(
        image,
        width: 90,
        height: 100,
        interpolation: img.Interpolation.linear,
      );
      final resizeDuration = DateTime.now().difference(resizeStartTime);
      debugPrint("[PROCESS] Resize: ${resizeDuration.inMilliseconds}ms");

      // Step 3: Convert to raw RGB data (27,000 bytes: 90 * 100 * 3)
      final convertStartTime = DateTime.now();
      final rgbData = Uint8List(27000);
      int offset = 0;

      for (final pixel in resized) {
        rgbData[offset++] = pixel.r.toInt();
        rgbData[offset++] = pixel.g.toInt();
        rgbData[offset++] = pixel.b.toInt();
      }
      final convertDuration = DateTime.now().difference(convertStartTime);
      debugPrint("[PROCESS] RGB conversion: ${convertDuration.inMilliseconds}ms");

      final totalProcessDuration = DateTime.now().difference(processStartTime);
      debugPrint("[PROCESS] Total processing: ${totalProcessDuration.inMilliseconds}ms");
      debugPrint("[PROCESS] Output: ${rgbData.length} bytes");
      
      return rgbData;
    } catch (e, stackTrace) {
      debugPrint("[PROCESS] Error: $e");
      debugPrint("[PROCESS] Stack trace: $stackTrace");
      return null;
    }
  }
}

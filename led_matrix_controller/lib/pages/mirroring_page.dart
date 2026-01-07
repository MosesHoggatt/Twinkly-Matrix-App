import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../services/screen_capture.dart';
import '../services/ddp_sender.dart';
import '../providers/app_state.dart';

class MirroringPage extends ConsumerStatefulWidget {
  const MirroringPage({super.key});

  @override
  ConsumerState<MirroringPage> createState() => _MirroringPageState();
}

class _MirroringPageState extends ConsumerState<MirroringPage> {
  bool isCapturing = false;
  String statusMessage = "Ready to capture screen";
  int frameCount = 0;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      _checkCaptureStatus();
    } else {
      setState(() {
        statusMessage = "Click Start to begin desktop screen mirroring";
      });
    }
  }

  Future<void> _checkCaptureStatus() async {
    final capturing = await ScreenCaptureService.isCapturing();
    setState(() {
      isCapturing = capturing;
    });
  }

  Future<void> _startDesktopCapture() async {
    final fppIp = ref.read(fppIpProvider);
    
    setState(() {
      isCapturing = true;
      statusMessage = "Capturing...";
      frameCount = 0;
    });

    // Capture at ~20 FPS (50ms per frame)
    while (isCapturing) {
      try {
        final screenshotData = await ScreenCaptureService.captureScreenshot();
        if (screenshotData != null) {
          // Send to FPP via DDP
          await DDPSender.sendFrameStatic(fppIp, screenshotData);
          
          setState(() {
            frameCount++;
            if (frameCount % 20 == 0) {
              statusMessage = "Capturing... (Frames: $frameCount)";
            }
          });
        } else {
          setState(() {
            statusMessage = "Failed to capture screenshot - check logs";
          });
          break;
        }
        
        // Wait ~50ms for ~20 FPS
        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        debugPrint("[MirroringPage] Error: $e");
        setState(() {
          statusMessage = "Capture error: $e";
        });
        break;
      }
    }
  }

  Future<void> _toggleCapture() async {
    try {
      if (isCapturing) {
        final success = await ScreenCaptureService.stopCapture();
        if (success) {
          setState(() {
            isCapturing = false;
            statusMessage = "Screen capture stopped ($frameCount frames sent)";
          });
        } else {
          setState(() {
            statusMessage = "Failed to stop capture";
          });
        }
      } else {
        if (Platform.isAndroid) {
          // Android native capture
          final success = await ScreenCaptureService.startCapture();
          if (success) {
            setState(() {
              isCapturing = true;
              statusMessage = "Screen capture started (20 FPS)";
            });
          } else {
            setState(() {
              statusMessage = "Failed to start capture - check permissions";
            });
          }
        } else if (Platform.isLinux || Platform.isWindows) {
          // Desktop capture
          final success = await ScreenCaptureService.startCapture();
          if (success) {
            _startDesktopCapture();
          } else {
            setState(() {
              statusMessage = "Failed to initialize capture";
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        statusMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fppIp = ref.watch(fppIpProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Mirroring'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCapturing ? Colors.green : Colors.grey,
                  width: 3,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isCapturing ? Icons.videocam : Icons.videocam_off,
                      size: 80,
                      color: isCapturing ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isCapturing ? 'CAPTURING' : 'IDLE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCapturing ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    statusMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'FPP: $fppIp:4048',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Platform: ${Platform.operatingSystem}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _toggleCapture,
              style: ElevatedButton.styleFrom(
                backgroundColor: isCapturing ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              ),
              child: Text(
                isCapturing ? 'Stop Mirroring' : 'Start Mirroring',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Captures screen at 90x100 resolution (20 FPS) and sends to FPP via DDP',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

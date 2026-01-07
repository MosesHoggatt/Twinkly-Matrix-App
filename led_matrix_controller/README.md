# LED Matrix Controller

A Flutter application for controlling a 90x100 LED matrix display via Falcon Player (FPP) using the DDP (Distributed Display Protocol) and command UDP communication.

## Features

- **Game Controller Mode**: Control the LED display with game controller input (D-Pad, Action Buttons)
- **Screen Mirroring Mode**: Capture and mirror Android device screen to the LED matrix at 90x100 resolution
- **DDP Protocol**: Low-latency UDP communication with 10-byte header + 27,000 byte RGB payload
- **State Management**: Riverpod-based state management for FPP IP address and active mode

## Architecture

### Communication Protocols

1. **DDP (Distributed Display Protocol)** - UDP port 4048
   - 10-byte header with protocol identification, flags, and payload length
   - 27,000 bytes of RGB pixel data (90x100x3)
   - Fire-and-forget stateless communication

2. **Game Controller Commands** - UDP port 5000
   - JSON-formatted commands to Python Flask server
   - Commands: MOVE_UP, MOVE_DOWN, MOVE_LEFT, MOVE_RIGHT, ACTION_A/B/X/Y, START, SELECT
   - Custom parameter support for advanced game controls

### Project Structure

```
lib/
├── main.dart                 # App entry point, home screen with mode selector
├── pages/
│   ├── controller_page.dart  # Game controller UI with D-Pad and action buttons
│   └── mirroring_page.dart   # Screen mirroring UI with capture controls
├── services/
│   ├── ddp_sender.dart       # DDP protocol implementation
│   ├── command_sender.dart   # UDP command sender for game controller
│   └── screen_capture.dart   # Native Android screen capture bridge
├── widgets/
│   └── directional_pad.dart  # Interactive D-Pad widget
└── providers/
    └── app_state.dart        # Riverpod state management
```

## Android Configuration

### Permissions (AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION" />
```

### Native Implementation (Kotlin)

The `MainActivity.kt` provides:
- `MediaProjectionManager` for screen capture authorization
- `ScreenCaptureService` for background frame capture
- `ScreenCaptureThread` for 20 FPS frame delivery
- Method Channel for Dart-Kotlin communication

## Usage

### Home Screen

1. Select mode: **Controller** or **Mirroring**
2. Enter FPP IP address (default: 192.168.1.100)
3. Click **Launch Controller** or **Launch Mirroring**

### Controller Mode

- **D-Pad**: Send directional movement commands (MOVE_UP/DOWN/LEFT/RIGHT)
- **Action Buttons**: Send A/B/X/Y commands
- **START/SELECT**: Trigger special game commands

### Mirroring Mode

1. Click **Start Mirroring** to authorize screen capture
2. Device screen is captured at 90x100 resolution
3. Frames sent to FPP via DDP at 20 FPS
4. Click **Stop Mirroring** to stop capture

## Dependencies

- **flutter_riverpod**: ^2.4.0 - State management
- **build_runner**: ^2.4.0 - Code generation
- **riverpod_generator**: ^2.3.0 - Riverpod code generation

## Build & Run

### Android

```bash
flutter run -d android
```

### Windows (Desktop)

```bash
flutter run -d windows
```

### Debug with Logging

```bash
flutter run -v
```

## Development

### Add a New Service

```dart
import 'dart:developer' as developer;

class MyService {
  Future<bool> initialize() async {
    try {
      developer.log('MyService initialized');
      return true;
    } catch (e) {
      developer.log('Failed to initialize: $e');
      return false;
    }
  }
}
```

### Use Riverpod Provider

```dart
final myServiceProvider = FutureProvider<MyService>((ref) async {
  final service = MyService();
  await service.initialize();
  return service;
});
```

## Performance

- **Frame Rate**: 20 FPS (50ms per frame)
- **Resolution**: 90x100 pixels (27,000 bytes per frame)
- **Latency**: <10ms for command transmission
- **Screen Capture**: Native Android MediaProjection API

## Troubleshooting

### Screen Capture Permission Denied
- Ensure Android 12+ is running
- Check `RECORD_AUDIO` permission is granted
- Clear app cache and reinstall

### FPP Not Responding
- Verify FPP IP address is correct
- Ensure FPP is running and listening on port 4048
- Check network connectivity

### High CPU Usage
- Reduce frame rate in FPP settings
- Check for background tasks on device
- Profile with `flutter run --profile`

## License

Proprietary - TwinklyWall Project

# Desktop Screen Capture Implementation

## Overview
Added cross-platform screen capture support for Linux and Windows (including WSL) to the LED Matrix Controller Flutter app.

## Changes Made

### 1. **Updated Dependencies** (`pubspec.yaml`)
- Added `image: ^4.1.0` - For image processing and resizing
- Added `path_provider: ^2.1.0` - For file system operations

### 2. **Enhanced ScreenCaptureService** (`lib/services/screen_capture.dart`)
- **Platform Detection**: Checks if running on Android, Linux, or Windows
- **Android Support**: Maintains original native plugin calls via platform channels
- **Linux Implementation**:
  - Uses `gnome-screenshot` as primary method
  - Falls back to ImageMagick's `import` command if gnome-screenshot unavailable
- **Windows Implementation**:
  - Uses PowerShell to capture screen from clipboard
  - Falls back to `nircmd` utility if PowerShell method fails
- **Screenshot Processing**:
  - Captures raw pixel data
  - Automatically resizes to 90x100 resolution
  - Converts to RGB format (27,000 bytes: 90×100×3)
  - Compatible with DDP protocol requirements

### 3. **Enhanced DDPSender** (`lib/services/ddp_sender.dart`)
- Added static method `sendFrameStatic()` for desktop screen mirroring
- Maintains persistent socket for efficient frame sending
- Supports both instance-based (Android) and static (Desktop) usage
- Backward compatible with existing code

### 4. **Updated MirroringPage** (`lib/pages/mirroring_page.dart`)
- **Platform-aware UI**:
  - Shows platform information
  - Enables button on all platforms (Android, Linux, Windows)
- **Desktop Capture Loop**:
  - Captures at ~20 FPS (50ms per frame)
  - Sends frames to FPP server via DDP
  - Displays frame count and status updates
- **Error Handling**:
  - Graceful fallbacks if screenshot tools unavailable
  - Real-time error messages to user

## How It Works

### On Linux (WSL):
1. App calls `gnome-screenshot` to capture full screen
2. Image is read and decoded using the `image` package
3. Image is resized to 90x100 pixels
4. RGB data is extracted (3 bytes per pixel)
5. Frames are sent to FPP server at DDP port (4048)

### On Windows:
1. PowerShell command captures screen to clipboard
2. Image is saved to temporary file
3. Same processing as Linux (decode → resize → extract RGB)
4. Falls back to `nircmd` if PowerShell fails

### On Android:
- Uses native Android plugin (original implementation)
- Unchanged from previous version

## Testing
- ✅ Compiles without errors
- ✅ App runs on Linux desktop
- ✅ Screen Mirroring page displays platform info
- ✅ Start/Stop buttons functional
- ✅ Ready to test actual screen capture when tools are available

## Requirements for Desktop Use

### Linux:
- `gnome-screenshot` (usually pre-installed on GNOME desktops)
- OR ImageMagick (`import` command)

### Windows:
- PowerShell (built-in)
- OR `nircmd` (optional fallback)

### WSL on Windows:
- X11 forwarding configured for display capture
- OR Use the Windows implementation if WSL2 doesn't support graphical capture

## Usage
1. Launch app on desired platform
2. Navigate to Screen Mirroring page
3. Click "Start Mirroring"
4. App captures screen at 20 FPS and sends to FPP
5. Frame counter increments with each sent frame
6. Click "Stop Mirroring" to end session

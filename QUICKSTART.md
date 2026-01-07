# Quick Start Guide

## Running the Apps

### Python API Server (on FPP or local machine)

#### Development/Testing Mode
```bash
cd TwinklyWall
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python main.py --mode api
```

The API server will start on `http://0.0.0.0:5000`

#### Production Mode (systemd service on FPP)
See [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) for detailed installation steps.

Quick version:
```bash
# Install and start the service
cd /home/fpp/TwinklyWall
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
sudo cp twinklywall.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable twinklywall.service
sudo systemctl start twinklywall.service
```

### Flutter App

#### First Time Setup
```bash
cd led_matrix_controller
flutter pub get
```

#### Run the App
```bash
# Desktop (Linux)
flutter run -d linux

# Desktop (Windows)
flutter run -d windows

# Desktop (macOS)
flutter run -d macos

# Android
flutter run -d android

# iOS
flutter run -d ios
```

## Using the App

1. **Launch the Flutter app** on your device
2. **Enter FPP IP address** (e.g., `192.168.1.100`)
3. **Select "Video" mode**
4. **Click "Select Video"**
5. **Choose a video** from the list and adjust settings:
   - Loop playback (on/off)
   - Brightness (10% - 100%)
   - Playback FPS (10 - 60)
6. **Click "Play"** to start
7. **Click Stop** to end playback

## API Endpoints

The Python server provides these REST endpoints:

- `GET /api/health` - Health check
- `GET /api/videos` - List available videos
- `GET /api/status` - Current playback status
- `POST /api/play` - Start video playback
- `POST /api/stop` - Stop playback

### Example API Usage

```bash
# Check server health
curl http://192.168.1.100:5000/api/health

# List videos
curl http://192.168.1.100:5000/api/videos

# Play a video
curl -X POST http://192.168.1.100:5000/api/play \
  -H "Content-Type: application/json" \
  -d '{
    "video": "Shireworks - Trim.mp4",
    "loop": true,
    "brightness": 0.8,
    "playback_fps": 20
  }'

# Stop playback
curl -X POST http://192.168.1.100:5000/api/stop
```

## Troubleshooting

### "Connection refused" error
- Ensure Python API server is running
- Check FPP IP address is correct
- Verify both devices are on same network
- Check firewall settings (port 5000 must be open)

### "No videos found"
- Add video files to `TwinklyWall/assets/source_videos/`
- Ensure videos are rendered (have matching .npz files in `dotmatrix/rendered_videos/`)

### Service won't stay running
- Check logs: `sudo journalctl -u twinklywall.service -f`
- Verify virtual environment: `ls /home/fpp/TwinklyWall/.venv`
- Check permissions: `sudo chown -R fpp:fpp /home/fpp/TwinklyWall`

## Architecture

```
┌─────────────────────┐
│   Flutter App       │
│  (Mobile/Desktop)   │
└──────────┬──────────┘
           │ HTTP REST API
           │ (port 5000)
           ▼
┌─────────────────────┐
│  Python API Server  │
│   (Flask/CORS)      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Video Player      │
│   + DotMatrix       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   FPP Output        │
│  (LED Matrix)       │
└─────────────────────┘
```

## File Locations

### Python (on FPP)
- Application: `/home/fpp/TwinklyWall/`
- Service file: `/etc/systemd/system/twinklywall.service`
- Logs: `journalctl -u twinklywall.service`
- Source videos: `/home/fpp/TwinklyWall/assets/source_videos/`
- Rendered videos: `/home/fpp/TwinklyWall/dotmatrix/rendered_videos/`

### Flutter
- Application: `led_matrix_controller/`
- Video selector page: `lib/pages/video_selector_page.dart`
- API service: `lib/services/api_service.dart`

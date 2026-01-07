# TwinklyWall Video Control System

A Flutter mobile/desktop app that controls video playback on an LED matrix via a Python API server running on FPP (Falcon Player).

## What's New

✨ **Video Selection UI** - Choose videos directly from the Flutter app  
✨ **REST API Communication** - HTTP-based control for reliability  
✨ **Systemd Service** - Run continuously on FPP without terminal sessions  
✨ **Playback Controls** - Adjust brightness, FPS, and looping from the app  

## Project Structure

```
TwinklyWall_Project/
├── led_matrix_controller/          # Flutter App
│   ├── lib/
│   │   ├── pages/
│   │   │   ├── controller_page.dart      # Game controller
│   │   │   ├── mirroring_page.dart       # Screen mirroring
│   │   │   └── video_selector_page.dart  # 🆕 Video selection
│   │   ├── services/
│   │   │   └── api_service.dart          # 🆕 HTTP API client
│   │   └── main.dart                     # App entry point
│   └── pubspec.yaml
│
├── TwinklyWall/                     # Python Server
│   ├── main.py                      # Entry point
│   ├── api_server.py                # 🆕 Flask REST API
│   ├── video_player.py              # Video playback engine
│   ├── twinklywall.service          # 🆕 Systemd service file
│   ├── requirements.txt             # Python dependencies
│   ├── dotmatrix/                   # LED matrix rendering
│   └── assets/source_videos/        # Source video files
│
└── Documentation/
    ├── QUICKSTART.md                # 🆕 Quick start guide
    ├── RUNNING_ON_FPP.md            # 🆕 FPP setup instructions
    ├── COMMUNICATION_GUIDE.md       # 🆕 API documentation
    └── SETUP_INSTRUCTIONS.md        # 🆕 Detailed setup guide
```

## Quick Start

### 1. Set Up Python Server on FPP

```bash
# SSH to FPP
ssh fpp@<fpp-ip>

# Install and set up
cd /home/fpp
git clone <your-repo> TwinklyWall
cd TwinklyWall
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Install as service
sudo cp twinklywall.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable twinklywall.service
sudo systemctl start twinklywall.service
```

### 2. Run Flutter App

```bash
cd led_matrix_controller
flutter pub get
flutter run
```

### 3. Use the App

1. Enter FPP IP address (e.g., `192.168.1.100`)
2. Select **"Video"** mode
3. Click **"Select Video"**
4. Choose a video, adjust settings, and click **"Play"**

## Features

### Flutter App
- 📱 **Multi-platform** - Runs on Android, iOS, Linux, Windows, macOS
- 🎮 **Three modes** - Controller, Video, Mirroring
- 🎬 **Video selection** - Browse and play videos from the server
- ⚙️ **Playback controls** - Brightness, FPS, looping
- 📊 **Status display** - Shows current playback state

### Python Server
- 🌐 **REST API** - HTTP endpoints for control
- 🧵 **Multi-threaded** - Non-blocking video playback
- 🔄 **Auto-restart** - Systemd keeps it running
- 📝 **Logging** - Full systemd journal integration
- 🎨 **LED output** - Optimized FPP rendering

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/health` | GET | Health check |
| `/api/videos` | GET | List available videos |
| `/api/status` | GET | Current playback status |
| `/api/play` | POST | Start video playback |
| `/api/stop` | POST | Stop playback |

## Communication Flow

```
┌──────────────┐                    ┌──────────────┐
│              │   HTTP REST API    │              │
│ Flutter App  │◄──────────────────►│ Python Flask │
│              │   Port 5000        │   Server     │
└──────────────┘                    └──────┬───────┘
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │ Video Player │
                                    │  DotMatrix   │
                                    └──────┬───────┘
                                           │
                                           ▼
                                    ┌──────────────┐
                                    │  FPP Output  │
                                    │ (LED Matrix) │
                                    └──────────────┘
```

## Managing the Service

```bash
# Start/stop/restart
sudo systemctl start twinklywall.service
sudo systemctl stop twinklywall.service
sudo systemctl restart twinklywall.service

# View logs
sudo journalctl -u twinklywall.service -f

# Check status
sudo systemctl status twinklywall.service
```

## Documentation

- **[QUICKSTART.md](QUICKSTART.md)** - Quick reference guide
- **[RUNNING_ON_FPP.md](RUNNING_ON_FPP.md)** - How to run continuously on FPP
- **[COMMUNICATION_GUIDE.md](COMMUNICATION_GUIDE.md)** - API and architecture details
- **[SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md)** - Complete installation guide

## Testing

### Test Python API
```bash
# Health check
curl http://localhost:5000/api/health

# List videos
curl http://localhost:5000/api/videos

# Play video
curl -X POST http://localhost:5000/api/play \
  -H "Content-Type: application/json" \
  -d '{"video": "Shireworks - Trim.mp4", "loop": true}'
```

### Test Flutter App
```bash
cd led_matrix_controller
flutter test
```

## Troubleshooting

### Can't connect to server
- ✓ Verify service is running: `sudo systemctl status twinklywall.service`
- ✓ Check logs: `sudo journalctl -u twinklywall.service -n 50`
- ✓ Test locally: `curl http://localhost:5000/api/health`
- ✓ Check firewall: `sudo ufw allow 5000/tcp`

### No videos showing
- ✓ Add videos to: `TwinklyWall/assets/source_videos/`
- ✓ Ensure rendered versions exist in: `dotmatrix/rendered_videos/`
- ✓ Check permissions: `sudo chown -R fpp:fpp /home/fpp/TwinklyWall`

### Service won't start
- ✓ Check logs: `sudo journalctl -u twinklywall.service -n 100`
- ✓ Verify venv exists: `ls /home/fpp/TwinklyWall/.venv`
- ✓ Reinstall requirements: `pip install -r requirements.txt`

## Requirements

### Flutter App
- Flutter SDK 3.10+
- Dart 3.0+
- Dependencies: flutter_riverpod, http

### Python Server
- Python 3.8+
- pygame >= 2.5.0
- numpy >= 1.20.0
- flask >= 3.0.0
- flask-cors >= 4.0.0

## Security Note

⚠️ The API has **no authentication**. It's designed for trusted local networks only. Do not expose port 5000 to the internet.

## License

[Your License Here]

## Credits

Built for controlling TwinklyWall LED matrix displays via FPP (Falcon Player Platform).

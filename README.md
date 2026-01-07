# TwinklyWall Project

A complete LED matrix control system with Flutter mobile/desktop app and Python backend for FPP (Falcon Player) integration.

## Project Structure

```
TwinklyWall_Project/
├── TwinklyWall/              # Python backend (DDP LED control)
│   ├── main.py               # Main entry point
│   ├── api_server.py         # Flask REST API server
│   ├── dotmatrix/            # LED matrix rendering engine
│   ├── games/                # Games (Tetris, etc.)
│   └── assets/               # Video files, images, etc.
│
├── led_matrix_controller/    # Flutter frontend app
│   ├── lib/
│   │   ├── main.dart         # App entry point
│   │   ├── pages/            # UI pages (controller, video selector, mirroring)
│   │   ├── services/         # API client, screen capture
│   │   └── providers/        # Riverpod state management
│   └── pubspec.yaml
│
└── Documentation/
    ├── QUICKSTART.md
    ├── SETUP_INSTRUCTIONS.md
    ├── RUNNING_ON_FPP.md
    └── COMMUNICATION_GUIDE.md
```

## Quick Start

### On FPP Device

1. **Clone the repository:**
   ```bash
   cd ~
   git clone https://github.com/Endless-98/Twinkly-Matrix-App.git TwinklyWall_Project
   cd TwinklyWall_Project
   ```

2. **Set up Python backend:**
   ```bash
   cd TwinklyWall
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```

3. **Install systemd service:**
   ```bash
   sudo cp twinklywall.service /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable twinklywall
   sudo systemctl start twinklywall
   ```

4. **Update later:**
   ```bash
   cd ~/TwinklyWall_Project
   git pull
   sudo systemctl restart twinklywall
   ```

### On Development Machine

1. **Flutter app:**
   ```bash
   cd led_matrix_controller
   flutter pub get
   flutter run
   ```

2. **Python backend (local testing):**
   ```bash
   cd TwinklyWall
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   python main.py --mode api
   ```

## Features

- **Video Playback**: Browse and play pre-rendered videos on the LED matrix
- **Screen Mirroring**: Mirror your desktop screen to the LED matrix in real-time
- **Manual Control**: Control individual LED brightness and patterns
- **REST API**: Control the matrix remotely via HTTP API
- **DDP Protocol**: Efficient LED data transmission to FPP

## Architecture

- **Flutter App** (Mobile/Desktop) → HTTP REST API → **Python Backend** → DDP Protocol → **FPP** → LED Matrix
- Communication on port 5000 (HTTP API)
- LED data transmission on port 4048 (DDP)

## Documentation

- [QUICKSTART.md](QUICKSTART.md) - Quick reference guide
- [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) - Detailed setup instructions
- [RUNNING_ON_FPP.md](RUNNING_ON_FPP.md) - FPP deployment guide
- [COMMUNICATION_GUIDE.md](COMMUNICATION_GUIDE.md) - API documentation

## Requirements

### Python Backend
- Python 3.8+
- NumPy, Pillow, Flask
- FPP with DDP output configured

### Flutter App
- Flutter 3.10+
- Dart SDK
- FFmpeg (for screen mirroring on Linux)

## License

[Your License Here]

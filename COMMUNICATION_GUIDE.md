# Communication Architecture

## Overview

This document explains how the Flutter app and Python server communicate to control video playback on the LED matrix.

## Communication Protocol

The apps communicate via **HTTP REST API** over the local network.

```
Flutter App ←→ HTTP/JSON (Port 5000) ←→ Python Flask Server
```

### Why HTTP/REST?
- Simple and reliable
- Works across different platforms (mobile, desktop, web)
- Easy to debug and test
- No complex socket management
- Supports CORS for web builds

## API Specification

### Base URL
```
http://<FPP_IP_ADDRESS>:5000
```

### Endpoints

#### 1. Health Check
```http
GET /api/health
```
**Response:**
```json
{
  "status": "ok"
}
```

#### 2. List Available Videos
```http
GET /api/videos
```
**Response:**
```json
{
  "videos": [
    "Shireworks - Trim.mp4",
    "Star-Spangled Banner - HD Video Background Loop.mp4",
    "Gandalf vs Balrog.mp4"
  ]
}
```

#### 3. Play Video
```http
POST /api/play
Content-Type: application/json

{
  "video": "Shireworks - Trim.mp4",
  "loop": true,
  "brightness": 0.8,
  "playback_fps": 20.0
}
```
**Response:**
```json
{
  "status": "playing",
  "video": "Shireworks - Trim.mp4",
  "rendered_file": "Shireworks - Trim_90x50_20fps.npz"
}
```

#### 4. Stop Playback
```http
POST /api/stop
```
**Response:**
```json
{
  "status": "stopped"
}
```

#### 5. Get Status
```http
GET /api/status
```
**Response:**
```json
{
  "playing": true,
  "video": "Shireworks - Trim.mp4"
}
```

## Flutter Implementation

### API Service (`lib/services/api_service.dart`)

The `ApiService` class handles all HTTP communication:

```dart
class ApiService {
  final String host;
  final int port;
  
  String get _baseUrl => 'http://$host:$port';
  
  // Methods:
  // - getAvailableVideos() -> List<String>
  // - playVideo(name, loop, brightness, fps) -> void
  // - stopPlayback() -> void
  // - getStatus() -> Map<String, dynamic>
}
```

### State Management

Uses **Riverpod** for state management:

```dart
// Stores the FPP IP address
final fppIpProvider = StateProvider<String>((ref) => '192.168.1.100');

// Stores the current mode (controller, video, mirroring)
final activeModeProvider = StateProvider<ActiveMode>((ref) => ActiveMode.controller);
```

### Video Selector Page

The `VideoSelectorPage` widget:
1. Fetches available videos from the API on load
2. Displays them in a list
3. Allows user to configure playback settings
4. Sends play/stop commands to the API
5. Shows current playback status

## Python Implementation

### Flask Server (`api_server.py`)

The Flask application provides the REST API:

```python
app = Flask(__name__)
CORS(app)  # Enable cross-origin requests for web builds

# Global state
current_player = None
current_matrix = None
playback_active = False
```

### Threading Model

Video playback runs in a **separate thread** to prevent blocking API requests:

```python
playback_thread = threading.Thread(
    target=play_video_thread,
    args=(video_path, loop, speed, brightness, fps),
    daemon=True
)
playback_thread.start()
```

This allows:
- API to remain responsive while video plays
- Multiple API calls without waiting for playback to finish
- Clean shutdown via stop command

### Video Resolution

The server automatically maps source videos to rendered versions:

```python
def get_video_name_from_source(source_filename):
    """Convert 'Shireworks - Trim.mp4' to 'Shireworks - Trim_90x50_20fps.npz'"""
    base_name = Path(source_filename).stem
    for rendered_file in rendered_videos_dir.glob(f"{base_name}*.npz"):
        return rendered_file.name
    return None
```

## Running as a Service

### Systemd Service Configuration

The `twinklywall.service` file ensures the API server:
- Starts automatically on boot
- Restarts if it crashes
- Runs as the `fpp` user
- Logs to systemd journal

```ini
[Service]
ExecStart=/home/fpp/TwinklyWall/.venv/bin/python main.py --mode api
Restart=always
RestartSec=10
```

### Benefits of Service Mode

1. **Automatic startup** - No manual intervention needed
2. **Crash recovery** - Restarts automatically after failures
3. **Background operation** - Runs independently of terminal sessions
4. **Logging** - All output captured in systemd journal
5. **Process management** - Easy start/stop/restart via `systemctl`

## Network Requirements

### Port Configuration
- **Port 5000** must be accessible on the FPP device
- Firewall must allow incoming TCP connections on port 5000
- Both devices must be on the same local network

### Firewall Setup
```bash
sudo ufw allow 5000/tcp
```

## Error Handling

### Flutter Side
```dart
try {
  final videos = await apiService.getAvailableVideos();
  // Success
} catch (e) {
  // Show error to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e'))
  );
}
```

### Python Side
```python
@app.route('/api/videos')
def get_videos():
    try:
        # Process request
        return jsonify({'videos': videos})
    except Exception as e:
        return jsonify({'error': str(e)}), 500
```

## Testing the Communication

### 1. Test Server Health
```bash
curl http://192.168.1.100:5000/api/health
```

### 2. Test Video Listing
```bash
curl http://192.168.1.100:5000/api/videos
```

### 3. Test Video Playback
```bash
curl -X POST http://192.168.1.100:5000/api/play \
  -H "Content-Type: application/json" \
  -d '{"video": "Shireworks - Trim.mp4", "loop": true}'
```

### 4. Monitor Logs
```bash
sudo journalctl -u twinklywall.service -f
```

## Security Considerations

⚠️ **Important:** This API has no authentication!

- Designed for **trusted local networks only**
- Anyone on the network can control the display
- Do NOT expose port 5000 to the internet
- Consider adding authentication for production use

## Debugging

### Common Issues

1. **Connection Refused**
   - Check: `sudo systemctl status twinklywall.service`
   - Check: `curl http://localhost:5000/api/health`
   - Solution: Ensure service is running and listening on 0.0.0.0

2. **Timeout**
   - Check network connectivity: `ping <fpp-ip>`
   - Check firewall: `sudo ufw status`
   - Solution: Allow port 5000 through firewall

3. **404 Not Found**
   - Check endpoint spelling in Flutter code
   - Check server routes in `api_server.py`
   - Solution: Verify URL paths match exactly

4. **500 Internal Server Error**
   - Check server logs: `journalctl -u twinklywall.service -n 100`
   - Look for Python exceptions
   - Solution: Fix code errors shown in logs

### Debug Mode

Run the server manually for detailed output:
```bash
cd /home/fpp/TwinklyWall
source .venv/bin/activate
python main.py --mode api
```

## Future Enhancements

Potential improvements:
- Add WebSocket support for real-time status updates
- Implement authentication (API keys, JWT)
- Add video upload functionality
- Support multiple simultaneous clients
- Add video preview thumbnails
- Implement playlist management

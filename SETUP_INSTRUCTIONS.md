# TwinklyWall Setup Instructions

## Installation on FPP (Falcon Player Platform)

### 1. Install Prerequisites

```bash
sudo apt update
sudo apt install -y python3-full python3-pip python3-venv git
```

### 2. Clone/Upload the Project

Option A - Clone from repository:
```bash
cd /home/fpp
git clone <your-repo-url> TwinklyWall
```

Option B - Upload files manually:
```bash
# Create directory
mkdir -p /home/fpp/TwinklyWall

# Upload your files using SCP or SFTP
# scp -r TwinklyWall/* fpp@<fpp-ip>:/home/fpp/TwinklyWall/
```

### 3. Set Up Python Virtual Environment

```bash
cd /home/fpp/TwinklyWall
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Test the API Server

```bash
# Make sure you're in the virtual environment
source .venv/bin/activate

# Run the API server
python main.py --mode api
```

The server should start on port 5000. Test it from another terminal:
```bash
curl http://localhost:5000/api/health
```

You should see: `{"status":"ok"}`

### 5. Install as a System Service

```bash
# Copy the service file to systemd directory
sudo cp twinklywall.service /etc/systemd/system/

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the service to start on boot
sudo systemctl enable twinklywall.service

# Start the service now
sudo systemctl start twinklywall.service

# Check the status
sudo systemctl status twinklywall.service
```

### 6. Manage the Service

View logs:
```bash
# View recent logs
sudo journalctl -u twinklywall.service -n 50

# Follow logs in real-time
sudo journalctl -u twinklywall.service -f
```

Control the service:
```bash
# Stop the service
sudo systemctl stop twinklywall.service

# Start the service
sudo systemctl start twinklywall.service

# Restart the service
sudo systemctl restart twinklywall.service

# Disable service from starting on boot
sudo systemctl disable twinklywall.service
```

### 7. Firewall Configuration (if needed)

If you have a firewall enabled, allow port 5000:
```bash
sudo ufw allow 5000/tcp
```

## Flutter App Setup

### 1. Install Flutter Dependencies

```bash
cd /path/to/led_matrix_controller
flutter pub get
```

### 2. Configure FPP IP Address

When you run the app, enter your FPP's IP address in the settings (e.g., `192.168.1.100`).

### 3. Run the Flutter App

For desktop testing:
```bash
flutter run -d linux
# or
flutter run -d windows
# or
flutter run -d macos
```

For mobile:
```bash
flutter run -d android
# or
flutter run -d ios
```

## Usage

1. Start the Python API server on FPP (either manually or via systemd service)
2. Launch the Flutter app
3. Enter the FPP IP address
4. Select "Video" mode
5. Click "Select Video"
6. Choose a video from the list
7. Adjust settings (brightness, FPS, looping)
8. Click "Play" to start playback

## Troubleshooting

### Service won't start
- Check logs: `sudo journalctl -u twinklywall.service -n 100`
- Verify Python virtual environment exists: `ls /home/fpp/TwinklyWall/.venv`
- Check file permissions: `sudo chown -R fpp:fpp /home/fpp/TwinklyWall`

### Connection refused from Flutter app
- Verify service is running: `sudo systemctl status twinklywall.service`
- Test locally: `curl http://localhost:5000/api/health`
- Check firewall settings
- Ensure FPP IP address is correct in Flutter app

### No videos showing
- Ensure source videos are in: `/home/fpp/TwinklyWall/assets/source_videos/`
- Ensure rendered videos exist: `/home/fpp/TwinklyWall/dotmatrix/rendered_videos/`
- Check file permissions: videos must be readable by the fpp user

### Video playback issues
- Check logs for errors: `sudo journalctl -u twinklywall.service -f`
- Verify rendered video format (.npz files)
- Adjust playback settings (FPS, brightness) in the app

## Network Configuration

The API server binds to `0.0.0.0:5000`, making it accessible on all network interfaces. 
Ensure your FPP and device running Flutter app are on the same network.

## Security Notes

- The API server has no authentication - it's designed for use on a trusted local network
- Consider using a firewall to restrict access to port 5000 if needed
- The service runs as the 'fpp' user with limited privileges

## Updating the Code

To update after making changes:
```bash
cd /home/fpp/TwinklyWall
git pull  # if using git
sudo systemctl restart twinklywall.service
```

## Removing the Service

```bash
sudo systemctl stop twinklywall.service
sudo systemctl disable twinklywall.service
sudo rm /etc/systemd/system/twinklywall.service
sudo systemctl daemon-reload
```

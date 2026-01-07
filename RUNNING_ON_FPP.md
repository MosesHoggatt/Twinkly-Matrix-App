# Running the App on FPP Continuously

## Complete Setup Guide

This guide shows you how to set up the Python API server to run continuously on your FPP (Falcon Player) device, so it starts automatically on boot and keeps running in the background.

## Step-by-Step Instructions

### 1. Prepare Your FPP Device

SSH into your FPP device:
```bash
ssh fpp@<your-fpp-ip>
# Default password is usually 'falcon'
```

### 2. Install Required Software

```bash
sudo apt update
sudo apt install -y python3-full python3-pip python3-venv git
```

### 3. Upload Your Project

Option A - If using git:
```bash
cd /home/fpp
git clone <your-repository-url> TwinklyWall
cd TwinklyWall
```

Option B - Upload manually via SCP:
```bash
# From your local machine:
cd /path/to/TwinklyWall_Project
scp -r TwinklyWall fpp@<fpp-ip>:/home/fpp/
```

### 4. Set Up Python Environment

```bash
cd /home/fpp/TwinklyWall
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

### 5. Test It Works

```bash
# Still in the virtual environment
python main.py --mode api
```

You should see:
```
Platform: Raspberry Pi
Mode: Headless
FPP Output: True
Starting Flask API server on port 5000...
```

Press Ctrl+C to stop the test.

### 6. Install as System Service

This is the key step that makes it run continuously:

```bash
# Copy the service file to systemd
sudo cp twinklywall.service /etc/systemd/system/

# Make systemd aware of the new service
sudo systemctl daemon-reload

# Enable it to start on boot
sudo systemctl enable twinklywall.service

# Start it now
sudo systemctl start twinklywall.service
```

### 7. Verify It's Running

```bash
# Check service status
sudo systemctl status twinklywall.service
```

You should see **"active (running)"** in green.

```bash
# Test the API
curl http://localhost:5000/api/health
```

You should get: `{"status":"ok"}`

## What This Achieves

✅ **Automatic Startup**: Starts when FPP boots  
✅ **Background Process**: Runs without a terminal session  
✅ **Crash Recovery**: Automatically restarts if it crashes  
✅ **Persistent**: Keeps running 24/7  
✅ **Managed**: Easy to control with systemctl commands  

## Managing the Service

### View Logs
```bash
# Recent logs
sudo journalctl -u twinklywall.service -n 50

# Follow logs in real-time (Ctrl+C to exit)
sudo journalctl -u twinklywall.service -f
```

### Control the Service
```bash
# Stop the service
sudo systemctl stop twinklywall.service

# Start the service
sudo systemctl start twinklywall.service

# Restart the service (after code updates)
sudo systemctl restart twinklywall.service

# Check status
sudo systemctl status twinklywall.service
```

### Disable Auto-Start
If you want to stop it from starting on boot:
```bash
sudo systemctl disable twinklywall.service
```

### Remove the Service Completely
```bash
sudo systemctl stop twinklywall.service
sudo systemctl disable twinklywall.service
sudo rm /etc/systemd/system/twinklywall.service
sudo systemctl daemon-reload
```

## Using the Flutter App

Once the service is running on FPP:

1. **Open the Flutter app** on your phone/tablet/computer
2. **Enter FPP IP address** (e.g., 192.168.1.100)
3. **Select "Video" mode**
4. **Click "Select Video"**
5. **Pick a video and adjust settings**
6. **Click "Play"**

The video will start playing on your LED matrix immediately!

## Troubleshooting

### Service fails to start

Check the logs:
```bash
sudo journalctl -u twinklywall.service -n 100
```

Common issues:
- **Virtual environment not found**: Re-run step 4
- **Permission denied**: Run `sudo chown -R fpp:fpp /home/fpp/TwinklyWall`
- **Module not found**: Re-install requirements in step 4

### Flutter app can't connect

1. Verify service is running:
   ```bash
   sudo systemctl status twinklywall.service
   ```

2. Test from FPP itself:
   ```bash
   curl http://localhost:5000/api/health
   ```

3. Test from your device:
   ```bash
   curl http://<fpp-ip>:5000/api/health
   ```

4. Check firewall:
   ```bash
   sudo ufw status
   sudo ufw allow 5000/tcp
   ```

### No videos showing

1. Check videos exist:
   ```bash
   ls /home/fpp/TwinklyWall/assets/source_videos/
   ls /home/fpp/TwinklyWall/dotmatrix/rendered_videos/
   ```

2. Ensure they're readable:
   ```bash
   sudo chown -R fpp:fpp /home/fpp/TwinklyWall
   ```

### After updating code

```bash
# If you updated via git:
cd /home/fpp/TwinklyWall
git pull

# Restart the service to use new code:
sudo systemctl restart twinklywall.service
```

## How It Works Behind the Scenes

1. **systemd** is Linux's service manager
2. When FPP boots, systemd reads `/etc/systemd/system/twinklywall.service`
3. It starts the Python app with the specified command
4. If the app crashes, systemd automatically restarts it (after 10 seconds)
5. All output goes to the **journal** (viewable with `journalctl`)
6. The service runs as user `fpp` for security

## Service File Explanation

```ini
[Unit]
Description=TwinklyWall LED Matrix API Server  # What it's called
After=network.target                          # Wait for network before starting

[Service]
Type=simple                                   # Simple, long-running process
User=fpp                                      # Run as 'fpp' user
WorkingDirectory=/home/fpp/TwinklyWall       # Run from this directory
ExecStart=/home/fpp/.../python main.py --mode api  # Command to run
Restart=always                                # Restart if it crashes
RestartSec=10                                 # Wait 10s before restarting

[Install]
WantedBy=multi-user.target                    # Start in multi-user mode (normal boot)
```

## Alternative: Running Without Service

If you don't want a systemd service, you can use **tmux** or **screen**:

```bash
# Install tmux
sudo apt install tmux

# Start a tmux session
tmux new -s twinklywall

# Activate venv and run
cd /home/fpp/TwinklyWall
source .venv/bin/activate
python main.py --mode api

# Detach: Press Ctrl+B, then D

# Reattach later:
tmux attach -t twinklywall
```

⚠️ This requires manual restart after reboot and won't auto-recover from crashes.

## Summary

You now have:
- ✅ Python API server running continuously on FPP
- ✅ Automatic startup on boot
- ✅ Automatic crash recovery
- ✅ Flutter app that can control video playback
- ✅ Full remote control of your LED matrix

The service will keep running until you explicitly stop it or the FPP device is powered off. When FPP reboots, the service starts automatically within seconds of boot.

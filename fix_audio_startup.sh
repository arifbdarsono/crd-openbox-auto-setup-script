#!/bin/bash

# Chrome Remote Desktop Audio Startup Fix
# Ensures audio works automatically after reboot/logout

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

log "Fixing Chrome Remote Desktop audio startup issues..."

# 1. Create improved Chrome Remote Desktop session script
log "Creating improved Chrome Remote Desktop session script..."
cat > ~/.chrome-remote-desktop-session << 'EOF'
#!/bin/bash

# Chrome Remote Desktop Session with Reliable Audio
# This script ensures audio works properly on every session start

# Set up environment
export DISPLAY=:20
export CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES="1920x1080,1680x1050,1600x1200,1400x1050,1280x1024,1024x768"

# Audio environment setup
export PULSE_RUNTIME_PATH="/run/user/$(id -u)/pulse"
export PULSE_SERVER="unix:${PULSE_RUNTIME_PATH}/native"

# Function to start audio with retries
start_audio() {
    local max_attempts=5
    local attempt=1
    
    echo "Starting audio system..."
    
    # Kill any existing PulseAudio processes
    pulseaudio --kill 2>/dev/null || true
    sleep 2
    
    while [ $attempt -le $max_attempts ]; do
        echo "Audio start attempt $attempt/$max_attempts"
        
        # Start PulseAudio
        pulseaudio --start --log-target=syslog --exit-idle-time=-1
        sleep 3
        
        # Check if PulseAudio is running
        if pulseaudio --check; then
            echo "PulseAudio started successfully"
            
            # Set default sink and unmute
            sleep 2
            DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null || pactl list short sinks | head -n1 | cut -f2)
            if [ ! -z "$DEFAULT_SINK" ]; then
                pactl set-default-sink "$DEFAULT_SINK" 2>/dev/null || true
                pactl set-sink-mute "$DEFAULT_SINK" false 2>/dev/null || true
                pactl set-sink-volume "$DEFAULT_SINK" 75% 2>/dev/null || true
                echo "Audio configured: sink=$DEFAULT_SINK, volume=75%, unmuted"
            fi
            break
        else
            echo "PulseAudio failed to start, retrying..."
            sleep 2
            ((attempt++))
        fi
    done
    
    if [ $attempt -gt $max_attempts ]; then
        echo "Warning: PulseAudio failed to start after $max_attempts attempts"
    fi
}

# Start audio system
start_audio

# Start OpenBox window manager
exec openbox-session
EOF

chmod +x ~/.chrome-remote-desktop-session

# 2. Create PulseAudio startup script
log "Creating PulseAudio startup script..."
mkdir -p ~/bin
cat > ~/bin/start-pulseaudio.sh << 'EOF'
#!/bin/bash

# PulseAudio Startup Script for Chrome Remote Desktop
# Ensures PulseAudio starts reliably

echo "Starting PulseAudio for Chrome Remote Desktop..."

# Set environment
export PULSE_RUNTIME_PATH="/run/user/$(id -u)/pulse"
export PULSE_SERVER="unix:${PULSE_RUNTIME_PATH}/native"

# Kill existing PulseAudio
pulseaudio --kill 2>/dev/null || true
sleep 2

# Remove stale runtime files
rm -rf /tmp/pulse-* 2>/dev/null || true
rm -rf "${PULSE_RUNTIME_PATH}" 2>/dev/null || true

# Create runtime directory
mkdir -p "${PULSE_RUNTIME_PATH}"

# Start PulseAudio with proper configuration
pulseaudio --start \
    --log-target=syslog \
    --exit-idle-time=-1 \
    --system=false \
    --disallow-exit \
    --disallow-module-loading=false

# Wait for PulseAudio to be ready
sleep 3

# Verify and configure
if pulseaudio --check; then
    echo "PulseAudio started successfully"
    
    # Configure default audio device
    DEFAULT_SINK=$(pactl list short sinks | head -n1 | cut -f2 2>/dev/null)
    if [ ! -z "$DEFAULT_SINK" ]; then
        pactl set-default-sink "$DEFAULT_SINK"
        pactl set-sink-mute "$DEFAULT_SINK" false
        pactl set-sink-volume "$DEFAULT_SINK" 75%
        echo "Audio configured: $DEFAULT_SINK"
    fi
else
    echo "Error: PulseAudio failed to start"
    exit 1
fi
EOF

chmod +x ~/bin/start-pulseaudio.sh

# 3. Create systemd user service for PulseAudio
log "Creating systemd user service for PulseAudio..."
mkdir -p ~/.config/systemd/user

cat > ~/.config/systemd/user/pulseaudio-crd.service << 'EOF'
[Unit]
Description=PulseAudio for Chrome Remote Desktop
After=graphical-session.target
Wants=graphical-session.target

[Service]
Type=notify
ExecStartPre=/bin/bash -c 'pulseaudio --kill || true'
ExecStartPre=/bin/sleep 2
ExecStart=/usr/bin/pulseaudio --daemonize=no --log-target=journal --exit-idle-time=-1
ExecStop=/usr/bin/pulseaudio --kill
Restart=always
RestartSec=5
Environment=PULSE_RUNTIME_PATH=%t/pulse

[Install]
WantedBy=default.target
EOF

# 4. Create improved OpenBox autostart
log "Updating OpenBox autostart configuration..."
cat > ~/.config/openbox/autostart << 'EOF'
#!/bin/bash

# OpenBox Autostart for Chrome Remote Desktop
# Ensures all services start in the correct order

# Wait for session to be ready
sleep 2

# Start PulseAudio if not already running
if ! pulseaudio --check; then
    echo "Starting PulseAudio from autostart..."
    ~/bin/start-pulseaudio.sh &
fi

# Wait for audio to be ready
sleep 3

# Start system tray
tint2 &

# Set wallpaper (if nitrogen is available)
if command -v nitrogen &> /dev/null; then
    nitrogen --restore &
fi

# Start file manager daemon
thunar --daemon &

# Start audio control in system tray (if available)
if command -v pavucontrol &> /dev/null; then
    # Don't start pavucontrol automatically, just make it available
    true
fi

# Optional: Start a terminal for debugging (uncomment if needed)
# xterm -geometry 80x24+10+10 -title "Debug Terminal" &
EOF

chmod +x ~/.config/openbox/autostart

# 5. Create improved PulseAudio configuration
log "Creating improved PulseAudio configuration..."
mkdir -p ~/.config/pulse

cat > ~/.config/pulse/default.pa << 'EOF'
#!/usr/bin/pulseaudio -nF

# PulseAudio Configuration for Chrome Remote Desktop
# Optimized for reliable remote audio streaming

# Load the default system configuration first
.include /etc/pulse/default.pa

# Unload module-suspend-on-idle to prevent audio from suspending
.ifexists module-suspend-on-idle.so
unload-module module-suspend-on-idle
.endif

# Load network modules for Chrome Remote Desktop
load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulse-socket

# Enable TCP protocol for remote desktop audio
load-module module-esound-protocol-tcp auth-ip-acl=127.0.0.1 port=16001

# Load additional modules for better remote desktop support
load-module module-remap-sink sink_name=crd_sink master=@DEFAULT_SINK@ channels=2

# Set default sample format and rate for better compatibility
set-default-sink @DEFAULT_SINK@
set-sink-volume @DEFAULT_SINK@ 75%
set-sink-mute @DEFAULT_SINK@ false
EOF

cat > ~/.config/pulse/daemon.conf << 'EOF'
# PulseAudio Daemon Configuration for Chrome Remote Desktop

# Basic settings
daemonize = no
fail = yes
allow-module-loading = yes
allow-exit = no
use-pid-file = yes
system-instance = no

# Audio quality settings
default-sample-format = s16le
default-sample-rate = 44100
default-sample-channels = 2
default-channel-map = front-left,front-right

# Buffer settings for remote desktop
default-fragments = 4
default-fragment-size-msec = 25

# Scheduling
high-priority = yes
nice-level = -11
realtime-scheduling = yes
realtime-priority = 5

# Disable idle exit
exit-idle-time = -1

# Logging
log-target = syslog
log-level = info
EOF

# 6. Enable systemd user service
log "Enabling PulseAudio systemd user service..."
systemctl --user daemon-reload
systemctl --user enable pulseaudio-crd.service
systemctl --user stop pulseaudio.service 2>/dev/null || true
systemctl --user disable pulseaudio.service 2>/dev/null || true

# 7. Create audio test and fix scripts
log "Creating improved audio management scripts..."

# Enhanced fix-audio script
cat > ~/bin/fix-audio.sh << 'EOF'
#!/bin/bash

echo "=== Chrome Remote Desktop Audio Fix ==="
echo

# Stop systemd PulseAudio service
echo "1. Stopping systemd PulseAudio services..."
systemctl --user stop pulseaudio-crd.service 2>/dev/null || true
systemctl --user stop pulseaudio.service 2>/dev/null || true

# Kill all PulseAudio processes
echo "2. Killing PulseAudio processes..."
pulseaudio --kill 2>/dev/null || true
killall pulseaudio 2>/dev/null || true
sleep 3

# Clean up runtime files
echo "3. Cleaning up runtime files..."
rm -rf /tmp/pulse-* 2>/dev/null || true
rm -rf "/run/user/$(id -u)/pulse" 2>/dev/null || true

# Start PulseAudio
echo "4. Starting PulseAudio..."
~/bin/start-pulseaudio.sh

# Start systemd service
echo "5. Starting systemd service..."
systemctl --user start pulseaudio-crd.service

# Test audio
echo "6. Testing audio..."
sleep 2
if pulseaudio --check; then
    echo "   ✓ PulseAudio is running"
    DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null)
    echo "   ✓ Default sink: $DEFAULT_SINK"
    pactl set-sink-volume @DEFAULT_SINK@ 75%
    pactl set-sink-mute @DEFAULT_SINK@ false
    echo "   ✓ Audio configured"
else
    echo "   ✗ PulseAudio failed to start"
fi

echo
echo "=== Fix Complete ==="
echo "Audio should now be working. Disconnect and reconnect your remote session if needed."
EOF

chmod +x ~/bin/fix-audio.sh

# Enhanced test-audio script
cat > ~/bin/test-audio.sh << 'EOF'
#!/bin/bash

echo "=== Chrome Remote Desktop Audio Test ==="
echo

# Check PulseAudio status
echo "1. PulseAudio Status:"
if pulseaudio --check; then
    echo "   ✓ PulseAudio is running"
    echo "   Process: $(pgrep -f pulseaudio | head -1)"
else
    echo "   ✗ PulseAudio is not running"
fi
echo

# Check systemd service
echo "2. Systemd Service Status:"
if systemctl --user is-active pulseaudio-crd.service >/dev/null 2>&1; then
    echo "   ✓ pulseaudio-crd.service is active"
else
    echo "   ✗ pulseaudio-crd.service is not active"
fi
echo

# List audio devices
echo "3. Available Audio Devices:"
pactl list short sinks 2>/dev/null | while read line; do
    echo "   - $line"
done || echo "   No audio devices found"
echo

# Show default device
echo "4. Default Audio Device:"
DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null || echo "None")
echo "   $DEFAULT_SINK"
echo

# Test volume levels
echo "5. Volume Levels:"
if [ "$DEFAULT_SINK" != "None" ]; then
    VOLUME=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | grep -o '[0-9]*%' | head -1)
    MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null)
    echo "   Volume: $VOLUME"
    echo "   Mute: $MUTE"
else
    echo "   No default sink available"
fi
echo

# Test audio output
echo "6. Audio Test:"
echo "   Playing test tone for 2 seconds..."
if command -v speaker-test >/dev/null 2>&1; then
    timeout 2 speaker-test -t sine -f 1000 -l 1 -s 1 >/dev/null 2>&1 || true
    echo "   Test tone played (if you heard it, audio is working)"
else
    echo "   speaker-test not available"
fi
echo

echo "=== Test Complete ==="
echo "If audio is not working, run: ~/bin/fix-audio.sh"
EOF

chmod +x ~/bin/test-audio.sh

# 8. Create startup verification script
cat > ~/bin/verify-audio-startup.sh << 'EOF'
#!/bin/bash

# Verify audio startup configuration
echo "=== Audio Startup Configuration Verification ==="
echo

echo "1. Chrome Remote Desktop session script:"
if [ -x ~/.chrome-remote-desktop-session ]; then
    echo "   ✓ ~/.chrome-remote-desktop-session exists and is executable"
else
    echo "   ✗ ~/.chrome-remote-desktop-session missing or not executable"
fi

echo "2. PulseAudio startup script:"
if [ -x ~/bin/start-pulseaudio.sh ]; then
    echo "   ✓ ~/bin/start-pulseaudio.sh exists and is executable"
else
    echo "   ✗ ~/bin/start-pulseaudio.sh missing or not executable"
fi

echo "3. Systemd user service:"
if [ -f ~/.config/systemd/user/pulseaudio-crd.service ]; then
    echo "   ✓ pulseaudio-crd.service exists"
    if systemctl --user is-enabled pulseaudio-crd.service >/dev/null 2>&1; then
        echo "   ✓ pulseaudio-crd.service is enabled"
    else
        echo "   ✗ pulseaudio-crd.service is not enabled"
    fi
else
    echo "   ✗ pulseaudio-crd.service missing"
fi

echo "4. OpenBox autostart:"
if [ -x ~/.config/openbox/autostart ]; then
    echo "   ✓ OpenBox autostart exists and is executable"
else
    echo "   ✗ OpenBox autostart missing or not executable"
fi

echo "5. PulseAudio configuration:"
if [ -f ~/.config/pulse/default.pa ]; then
    echo "   ✓ PulseAudio configuration exists"
else
    echo "   ✗ PulseAudio configuration missing"
fi

echo
echo "=== Verification Complete ==="
EOF

chmod +x ~/bin/verify-audio-startup.sh

# 9. Restart Chrome Remote Desktop service
log "Restarting Chrome Remote Desktop service..."
sudo systemctl restart chrome-remote-desktop@$USER 2>/dev/null || warn "Could not restart Chrome Remote Desktop service"

log "Audio startup fix completed!"

echo
echo -e "${GREEN}=== Audio Startup Fix Summary ===${NC}"
echo -e "${BLUE}✓ Improved Chrome Remote Desktop session script${NC}"
echo -e "${BLUE}✓ Created PulseAudio startup script${NC}"
echo -e "${BLUE}✓ Configured systemd user service${NC}"
echo -e "${BLUE}✓ Updated OpenBox autostart${NC}"
echo -e "${BLUE}✓ Optimized PulseAudio configuration${NC}"
echo -e "${BLUE}✓ Enhanced audio management scripts${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Reboot your system: sudo reboot"
echo "2. Test audio after reboot: ~/bin/test-audio.sh"
echo "3. If issues persist: ~/bin/fix-audio.sh"
echo "4. Verify configuration: ~/bin/verify-audio-startup.sh"
echo
echo -e "${GREEN}Audio should now start automatically after reboot/logout!${NC}"
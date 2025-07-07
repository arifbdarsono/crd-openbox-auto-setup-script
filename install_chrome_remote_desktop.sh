#!/bin/bash

# Chrome Remote Desktop Installation and Configuration Script
# For Ubuntu Minimal 20.04 with OpenBox and Audio Support

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

# Check Ubuntu version
if ! grep -q "20.04" /etc/os-release; then
    warn "This script is designed for Ubuntu 20.04. Your system may not be compatible."
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

log "Starting Chrome Remote Desktop installation and configuration..."

# Update system packages
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
log "Installing essential packages..."
sudo apt install -y \
    wget \
    curl \
    gnupg \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    dbus-x11 \
    xvfb \
    xbase-clients \
    python3-psutil

# Function to install package with error handling
install_package() {
    local package="$1"
    local critical="$2"
    
    if sudo apt install -y "$package" 2>/dev/null; then
        info "✓ Installed $package"
    else
        if [ "$critical" = "critical" ]; then
            error "Failed to install critical package: $package"
            return 1
        else
            warn "Could not install $package (non-critical, continuing...)"
        fi
    fi
}

# Enable universe repository if not already enabled
log "Ensuring universe repository is enabled..."
sudo add-apt-repository universe -y 2>/dev/null || true
sudo apt update

# Install X11 and OpenBox desktop environment (critical packages)
log "Installing X11 and OpenBox desktop environment..."
CRITICAL_PACKAGES="xorg openbox obconf tint2 thunar firefox xterm lxappearance"
for package in $CRITICAL_PACKAGES; do
    install_package "$package" "critical"
done

# Install additional useful packages (non-critical)
log "Installing additional desktop packages..."
ADDITIONAL_PACKAGES="nitrogen gmrun menu"
for package in $ADDITIONAL_PACKAGES; do
    install_package "$package" "optional"
done

# Install optional useful applications (non-critical)
log "Installing optional applications..."
OPTIONAL_PACKAGES="mousepad galculator gpicview file-roller htop obmenu"
for package in $OPTIONAL_PACKAGES; do
    install_package "$package" "optional"
done

# Install audio system (PulseAudio)
log "Installing PulseAudio for audio support..."
sudo apt install -y \
    pulseaudio \
    pulseaudio-utils \
    pavucontrol \
    alsa-utils \
    libasound2-dev

# Download and install Google Chrome (required for Chrome Remote Desktop)
log "Installing Google Chrome..."
if ! command -v google-chrome &> /dev/null; then
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
    sudo apt update
    sudo apt install -y google-chrome-stable
fi

# Download and install Chrome Remote Desktop
log "Installing Chrome Remote Desktop..."
CHROME_RDP_DEB="chrome-remote-desktop_current_amd64.deb"
if [ ! -f "/tmp/$CHROME_RDP_DEB" ]; then
    wget -O "/tmp/$CHROME_RDP_DEB" "https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb"
fi
sudo dpkg -i "/tmp/$CHROME_RDP_DEB" || sudo apt-get install -f -y

# Add current user to chrome-remote-desktop group
log "Adding user to chrome-remote-desktop group..."
sudo usermod -a -G chrome-remote-desktop $USER

# Create OpenBox configuration directory
log "Setting up OpenBox configuration..."
mkdir -p ~/.config/openbox

# Create OpenBox autostart script
cat > ~/.config/openbox/autostart << 'EOF'
#!/bin/bash

# OpenBox Autostart for Chrome Remote Desktop
# Ensures all services start in the correct order

# Wait for session to be ready
sleep 2

# Start PulseAudio if not already running (backup)
if ! pulseaudio --check; then
    echo "Starting PulseAudio from autostart..."
    pulseaudio --start --log-target=syslog --exit-idle-time=-1 &
    sleep 3
fi

# Start system tray
tint2 &

# Set wallpaper (if nitrogen is available)
if command -v nitrogen &> /dev/null; then
    nitrogen --restore &
fi

# Start file manager daemon
thunar --daemon &

# Optional: Start a terminal for debugging (uncomment if needed)
# xterm -geometry 80x24+10+10 -title "Debug Terminal" &
EOF

chmod +x ~/.config/openbox/autostart

# Create OpenBox menu configuration
log "Creating OpenBox menu configuration..."
cat > ~/.config/openbox/menu.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="Openbox 3">
    <item label="Terminal">
      <action name="Execute">
        <command>xterm</command>
      </action>
    </item>
    <item label="File Manager">
      <action name="Execute">
        <command>thunar</command>
      </action>
    </item>
    <item label="Web Browser">
      <action name="Execute">
        <command>firefox</command>
      </action>
    </item>
    <item label="Text Editor">
      <action name="Execute">
        <command>mousepad</command>
      </action>
    </item>
    <item label="Run">
      <action name="Execute">
        <command>gmrun</command>
      </action>
    </item>
    <separator />
    <menu id="applications-menu" label="Applications">
      <item label="Calculator">
        <action name="Execute">
          <command>galculator</command>
        </action>
      </item>
      <item label="Image Viewer">
        <action name="Execute">
          <command>gpicview</command>
        </action>
      </item>
      <item label="Archive Manager">
        <action name="Execute">
          <command>file-roller</command>
        </action>
      </item>
    </menu>
    <menu id="system-menu" label="System">
      <item label="Audio Control">
        <action name="Execute">
          <command>pavucontrol</command>
        </action>
      </item>
      <item label="Appearance">
        <action name="Execute">
          <command>lxappearance</command>
        </action>
      </item>
      <item label="OpenBox Config">
        <action name="Execute">
          <command>obconf</command>
        </action>
      </item>
      <item label="Task Manager">
        <action name="Execute">
          <command>xterm -e htop</command>
        </action>
      </item>
    </menu>
    <separator />
    <item label="Reconfigure">
      <action name="Reconfigure" />
    </item>
    <item label="Exit">
      <action name="Exit">
        <prompt>yes</prompt>
      </action>
    </item>
  </menu>
</openbox_menu>
EOF

# Create Chrome Remote Desktop session configuration
log "Configuring Chrome Remote Desktop session..."
mkdir -p ~/.config/chrome-remote-desktop

# Create the session script that Chrome Remote Desktop will use
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

# Configure PulseAudio for remote desktop
log "Configuring PulseAudio for remote desktop..."
mkdir -p ~/.config/pulse

# Create PulseAudio configuration for remote desktop
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

# Create PulseAudio daemon configuration
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

# Create systemd user service for PulseAudio
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

# Enable PulseAudio user service
systemctl --user daemon-reload
systemctl --user enable pulseaudio-crd.service
systemctl --user stop pulseaudio.service 2>/dev/null || true
systemctl --user disable pulseaudio.service 2>/dev/null || true

# Create a desktop entry for easy access
log "Creating desktop shortcuts..."
mkdir -p ~/Desktop
cat > ~/Desktop/chrome-remote-desktop-setup.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Chrome Remote Desktop Setup
Comment=Open Chrome Remote Desktop setup page
Exec=google-chrome https://remotedesktop.google.com/headless
Icon=google-chrome
Terminal=false
Categories=Network;RemoteAccess;
EOF

chmod +x ~/Desktop/chrome-remote-desktop-setup.desktop

# Create tint2 configuration for system tray
log "Configuring system tray..."
mkdir -p ~/.config/tint2
cat > ~/.config/tint2/tint2rc << 'EOF'
# Tint2 config for Chrome Remote Desktop

# Background
rounded = 0
border_width = 0
background_color = #000000 60
border_color = #ffffff 16

# Panel
panel_monitor = all
panel_position = bottom center horizontal
panel_size = 100% 30
panel_margin = 0 0
panel_padding = 7 0 7
panel_dock = 0
wm_menu = 1
panel_layer = bottom
panel_background_id = 1

# Taskbar
taskbar_mode = single_desktop
taskbar_padding = 2 3 2
taskbar_background_id = 0
taskbar_active_background_id = 0

# Tasks
task_icon = 1
task_text = 1
task_centered = 1
task_maximum_size = 140 35
task_padding = 6 2
task_background_id = 0
task_active_background_id = 0
task_urgent_background_id = 0
task_iconified_background_id = 0

# System tray
systray = 1
systray_padding = 0 4 5
systray_background_id = 0
systray_sort = ascending
systray_icon_size = 16
systray_icon_asb = 70 0 0

# Clock
time1_format = %H:%M
time2_format = %A %d %B
time1_font = sans 8
time2_font = sans 6
clock_font_color = #ffffff 76
clock_padding = 1 0
clock_background_id = 0
EOF

# Create helpful scripts
log "Creating helper scripts..."
mkdir -p ~/bin

# Script to restart Chrome Remote Desktop
cat > ~/bin/restart-crd.sh << 'EOF'
#!/bin/bash
sudo systemctl restart chrome-remote-desktop@$USER
echo "Chrome Remote Desktop service restarted"
EOF

# Script to check Chrome Remote Desktop status
cat > ~/bin/check-crd.sh << 'EOF'
#!/bin/bash
echo "Chrome Remote Desktop Service Status:"
sudo systemctl status chrome-remote-desktop@$USER

echo -e "\nActive sessions:"
ps aux | grep chrome-remote-desktop | grep -v grep

echo -e "\nPulseAudio status:"
pulseaudio --check && echo "PulseAudio is running" || echo "PulseAudio is not running"

echo -e "\nSystemd audio service:"
systemctl --user is-active pulseaudio-crd.service >/dev/null 2>&1 && echo "pulseaudio-crd.service is active" || echo "pulseaudio-crd.service is not active"
EOF

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
pulseaudio --start --log-target=syslog --exit-idle-time=-1

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

chmod +x ~/bin/restart-crd.sh ~/bin/check-crd.sh ~/bin/fix-audio.sh ~/bin/test-audio.sh

# Add ~/bin to PATH if not already there
if ! echo $PATH | grep -q "$HOME/bin"; then
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
fi

# Create installation summary
log "Creating installation summary..."
cat > ~/chrome-remote-desktop-setup-info.txt << EOF
Chrome Remote Desktop Installation Summary
==========================================

Installation completed on: $(date)

Next Steps:
1. Reboot your system or log out and log back in
2. Open Google Chrome and go to: https://remotedesktop.google.com/headless
3. Follow the setup instructions to authorize your computer
4. When prompted for the command, run it in the terminal
5. Set a PIN for remote access

Configuration Files Created:
- ~/.chrome-remote-desktop-session (session script)
- ~/.config/openbox/ (OpenBox configuration)
- ~/.config/pulse/default.pa (PulseAudio configuration)
- ~/.config/tint2/tint2rc (system tray configuration)

Helper Scripts:
- ~/bin/restart-crd.sh (restart Chrome Remote Desktop)
- ~/bin/check-crd.sh (check service status)

Audio Configuration:
- PulseAudio is configured for remote audio streaming
- Audio should work automatically when connected

Troubleshooting:
- If audio doesn't work, run: pulseaudio --kill && pulseaudio --start
- Check service status with: ~/bin/check-crd.sh
- Restart service with: ~/bin/restart-crd.sh

Desktop Environment:
- OpenBox window manager with system tray
- Right-click on desktop for menu
- File manager: Thunar
- Web browser: Firefox
- Terminal: xterm

For support, check the Chrome Remote Desktop documentation:
https://support.google.com/chrome/answer/1649523
EOF

# Final system configuration
log "Performing final system configuration..."

# Ensure services are enabled
sudo systemctl enable chrome-remote-desktop@$USER.service

# Set up audio group permissions
sudo usermod -a -G audio $USER

# Create a simple wallpaper directory
mkdir -p ~/Pictures/Wallpapers

log "Installation completed successfully!"
info "Please read the setup information in ~/chrome-remote-desktop-setup-info.txt"
warn "You need to reboot or log out/in for all changes to take effect"
warn "After reboot, open Chrome and visit https://remotedesktop.google.com/headless to complete setup"

echo
echo -e "${GREEN}=== Installation Summary ===${NC}"
echo -e "${BLUE}✓ Chrome Remote Desktop installed${NC}"
echo -e "${BLUE}✓ OpenBox desktop environment configured${NC}"
echo -e "${BLUE}✓ PulseAudio configured for remote audio${NC}"
echo -e "${BLUE}✓ System tray and basic applications installed${NC}"
echo -e "${BLUE}✓ Helper scripts created in ~/bin/${NC}"
echo
echo -e "${YELLOW}Next: Reboot and visit https://remotedesktop.google.com/headless${NC}"
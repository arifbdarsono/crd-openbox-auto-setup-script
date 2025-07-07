#!/bin/bash

# Chrome Remote Desktop Installation and Configuration Script
# For Ubuntu Minimal 20.04 with OpenBox

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
    warn "This script tested on Ubuntu 20.04 only. Your system may not be compatible."
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
sudo usermod -aG chrome-remote-desktop $USER

# Create OpenBox configuration directory
log "Setting up OpenBox configuration..."
mkdir -p ~/.config/openbox

# Create OpenBox autostart script
cat > ~/.config/openbox/autostart << 'EOF'
#!/bin/bash

# Start PulseAudio
pulseaudio --start --log-target=syslog &

# Start system tray
tint2 &

# Set wallpaper (if nitrogen is available)
if command -v nitrogen &> /dev/null; then
    nitrogen --restore &
fi

# Start file manager daemon
thunar --daemon &

# Optional: Start a terminal
# xterm &
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

# Set up environment
export DISPLAY=:20
export CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES="1920x1080,1680x1050,1600x1200,1400x1050,1280x1024,1024x768"

# Start PulseAudio for audio
export PULSE_RUNTIME_PATH="/run/user/$(id -u)/pulse"
pulseaudio --start --log-target=syslog

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

# Load audio drivers
.include /etc/pulse/default.pa

# Load module for Chrome Remote Desktop audio streaming
load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulse-socket

# Enable audio over network (for remote desktop)
load-module module-esound-protocol-tcp auth-ip-acl=127.0.0.1
EOF

# Create systemd user service for PulseAudio (optional)
mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/pulseaudio.service << 'EOF'
[Unit]
Description=PulseAudio Sound System
After=graphical-session.target

[Service]
Type=notify
ExecStart=/usr/bin/pulseaudio --daemonize=no --log-target=journal
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

# Enable PulseAudio user service
systemctl --user daemon-reload
systemctl --user enable pulseaudio.service

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
EOF

chmod +x ~/bin/restart-crd.sh ~/bin/check-crd.sh

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
- If audio doesn't work, try: pulseaudio --kill && pulseaudio --start
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
sudo usermod -aG audio $USER

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
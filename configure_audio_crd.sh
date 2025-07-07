#!/bin/bash

# Chrome Remote Desktop Audio Configuration Script
# Troubleshooting and optimization for audio streaming

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

# Function to test audio
test_audio() {
    log "Testing audio configuration..."
    
    # Check if PulseAudio is running
    if pulseaudio --check; then
        info "PulseAudio is running"
    else
        warn "PulseAudio is not running, attempting to start..."
        pulseaudio --start
    fi
    
    # List audio devices
    info "Available audio devices:"
    pactl list short sinks
    
    # Test audio output
    info "Testing audio output (you should hear a beep)..."
    pactl play-sample bell-window-system 2>/dev/null || {
        warn "Could not play test sound. Generating tone instead..."
        speaker-test -t sine -f 1000 -l 1 -s 1 2>/dev/null || {
            warn "No audio test available. Please test manually after connecting."
        }
    }
}

# Function to fix common audio issues
fix_audio_issues() {
    log "Fixing common audio issues..."
    
    # Kill and restart PulseAudio
    pulseaudio --kill 2>/dev/null || true
    sleep 2
    pulseaudio --start
    
    # Set default sink
    DEFAULT_SINK=$(pactl list short sinks | head -n1 | cut -f2)
    if [ ! -z "$DEFAULT_SINK" ]; then
        pactl set-default-sink "$DEFAULT_SINK"
        info "Set default audio sink to: $DEFAULT_SINK"
    fi
    
    # Unmute and set volume
    pactl set-sink-mute @DEFAULT_SINK@ false
    pactl set-sink-volume @DEFAULT_SINK@ 75%
    info "Audio unmuted and volume set to 75%"
}

# Function to optimize Chrome Remote Desktop for audio
optimize_crd_audio() {
    log "Optimizing Chrome Remote Desktop for audio..."
    
    # Create optimized PulseAudio configuration
    mkdir -p ~/.config/pulse
    
    cat > ~/.config/pulse/daemon.conf << 'EOF'
# PulseAudio daemon configuration for Chrome Remote Desktop

# Increase buffer sizes for better remote audio performance
default-sample-format = s16le
default-sample-rate = 44100
default-sample-channels = 2

# Optimize for network streaming
default-fragments = 8
default-fragment-size-msec = 25

# Enable real-time scheduling
high-priority = yes
nice-level = -11

# Disable suspend to prevent audio dropouts
exit-idle-time = -1
EOF

    # Create module configuration for remote desktop
    cat > ~/.config/pulse/default.pa << 'EOF'
#!/usr/bin/pulseaudio -nF

# Load the default configuration
.include /etc/pulse/default.pa

# Load additional modules for Chrome Remote Desktop
load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/pulse-socket

# Enable network audio (for remote desktop)
load-module module-esound-protocol-tcp auth-ip-acl=127.0.0.1 port=16001

# Load module for better audio quality over network
load-module module-remap-sink sink_name=remote_audio_sink master=@DEFAULT_SINK@ channels=2

# Set up audio forwarding for Chrome Remote Desktop
load-module module-tunnel-sink server=127.0.0.1:16001 sink_name=crd_tunnel
EOF

    info "PulseAudio configuration optimized for remote desktop"
}

# Function to create audio test script
create_audio_test_script() {
    log "Creating audio test script..."
    
    mkdir -p ~/bin
    cat > ~/bin/test-audio.sh << 'EOF'
#!/bin/bash

echo "=== Chrome Remote Desktop Audio Test ==="
echo

# Check PulseAudio status
echo "1. PulseAudio Status:"
if pulseaudio --check; then
    echo "   ✓ PulseAudio is running"
else
    echo "   ✗ PulseAudio is not running"
    echo "   Attempting to start..."
    pulseaudio --start
fi
echo

# List audio devices
echo "2. Available Audio Devices:"
pactl list short sinks | while read line; do
    echo "   - $line"
done
echo

# Show default device
echo "3. Default Audio Device:"
DEFAULT_SINK=$(pactl get-default-sink)
echo "   $DEFAULT_SINK"
echo

# Test volume levels
echo "4. Volume Levels:"
pactl list sinks | grep -A 15 "Name: $DEFAULT_SINK" | grep "Volume:" | head -1
echo

# Test audio output
echo "5. Audio Test:"
echo "   Playing test tone for 2 seconds..."
( speaker-test -t sine -f 1000 -l 1 -s 1 >/dev/null 2>&1 & sleep 2; kill $! 2>/dev/null ) || {
    echo "   Could not play test tone. Audio may not be working."
}
echo

echo "=== Test Complete ==="
echo "If you can hear the test tone, audio is working correctly."
echo "If not, try running: ~/bin/fix-audio.sh"
EOF

    chmod +x ~/bin/test-audio.sh
    info "Audio test script created at ~/bin/test-audio.sh"
}

# Function to create audio fix script
create_audio_fix_script() {
    log "Creating audio fix script..."
    
    cat > ~/bin/fix-audio.sh << 'EOF'
#!/bin/bash

echo "=== Chrome Remote Desktop Audio Fix ==="
echo

# Kill PulseAudio
echo "1. Restarting PulseAudio..."
pulseaudio --kill 2>/dev/null || true
sleep 3
pulseaudio --start
echo "   ✓ PulseAudio restarted"
echo

# Set default sink
echo "2. Setting default audio device..."
DEFAULT_SINK=$(pactl list short sinks | head -n1 | cut -f2)
if [ ! -z "$DEFAULT_SINK" ]; then
    pactl set-default-sink "$DEFAULT_SINK"
    echo "   ✓ Default sink set to: $DEFAULT_SINK"
else
    echo "   ✗ No audio devices found"
fi
echo

# Unmute and set volume
echo "3. Configuring audio levels..."
pactl set-sink-mute @DEFAULT_SINK@ false
pactl set-sink-volume @DEFAULT_SINK@ 75%
echo "   ✓ Audio unmuted and volume set to 75%"
echo

# Restart Chrome Remote Desktop
echo "4. Restarting Chrome Remote Desktop..."
sudo systemctl restart chrome-remote-desktop@$USER 2>/dev/null || {
    echo "   ! Could not restart Chrome Remote Desktop service"
    echo "   Try running: sudo systemctl restart chrome-remote-desktop@$USER"
}
echo

echo "=== Fix Complete ==="
echo "Audio should now be working. Test with: ~/bin/test-audio.sh"
echo "If problems persist, disconnect and reconnect your remote session."
EOF

    chmod +x ~/bin/fix-audio.sh
    info "Audio fix script created at ~/bin/fix-audio.sh"
}

# Function to show audio status
show_audio_status() {
    echo -e "${BLUE}=== Chrome Remote Desktop Audio Status ===${NC}"
    echo
    
    # PulseAudio status
    echo -e "${GREEN}PulseAudio Status:${NC}"
    if pulseaudio --check; then
        echo "  ✓ Running"
    else
        echo "  ✗ Not running"
    fi
    echo
    
    # Audio devices
    echo -e "${GREEN}Audio Devices:${NC}"
    pactl list short sinks | while read line; do
        echo "  - $line"
    done
    echo
    
    # Default device
    echo -e "${GREEN}Default Device:${NC}"
    DEFAULT_SINK=$(pactl get-default-sink 2>/dev/null || echo "None")
    echo "  $DEFAULT_SINK"
    echo
    
    # Chrome Remote Desktop status
    echo -e "${GREEN}Chrome Remote Desktop Status:${NC}"
    if systemctl --user is-active chrome-remote-desktop >/dev/null 2>&1; then
        echo "  ✓ Service is running"
    else
        echo "  ✗ Service is not running"
    fi
    echo
    
    # Active sessions
    echo -e "${GREEN}Active Remote Sessions:${NC}"
    SESSIONS=$(ps aux | grep chrome-remote-desktop | grep -v grep | wc -l)
    if [ $SESSIONS -gt 0 ]; then
        echo "  ✓ $SESSIONS active session(s)"
    else
        echo "  - No active sessions"
    fi
    echo
}

# Main menu
show_menu() {
    echo -e "${BLUE}=== Chrome Remote Desktop Audio Configuration ===${NC}"
    echo
    echo "1. Show audio status"
    echo "2. Test audio"
    echo "3. Fix audio issues"
    echo "4. Optimize audio for remote desktop"
    echo "5. Create helper scripts"
    echo "6. Run all optimizations"
    echo "7. Exit"
    echo
}

# Main script logic
case "${1:-menu}" in
    "status")
        show_audio_status
        ;;
    "test")
        test_audio
        ;;
    "fix")
        fix_audio_issues
        ;;
    "optimize")
        optimize_crd_audio
        ;;
    "scripts")
        create_audio_test_script
        create_audio_fix_script
        ;;
    "all")
        optimize_crd_audio
        create_audio_test_script
        create_audio_fix_script
        fix_audio_issues
        test_audio
        ;;
    "menu"|*)
        while true; do
            show_menu
            read -p "Select an option (1-7): " choice
            case $choice in
                1) show_audio_status ;;
                2) test_audio ;;
                3) fix_audio_issues ;;
                4) optimize_crd_audio ;;
                5) create_audio_test_script; create_audio_fix_script ;;
                6) 
                    optimize_crd_audio
                    create_audio_test_script
                    create_audio_fix_script
                    fix_audio_issues
                    test_audio
                    ;;
                7) exit 0 ;;
                *) error "Invalid option. Please select 1-7." ;;
            esac
            echo
            read -p "Press Enter to continue..."
            clear
        done
        ;;
esac
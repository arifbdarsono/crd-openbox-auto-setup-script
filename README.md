# Chrome Remote Desktop Auto Setup Script with OpenBox on Ubuntu 20.04

This repository contains scripts to automatically install and configure Chrome Remote Desktop with OpenBox on Ubuntu minimal 20.04.

## Quick Start

### 1. Download and Run Installation Script

```bash
# Download the installation script
wget https://raw.githubusercontent.com/arifbdarsono/crd-openbox-auto-setup-script/main/install_chrome_remote_desktop.sh

# Make it executable
chmod +x install_chrome_remote_desktop.sh

# Run the installation (do NOT run as root)
./install_chrome_remote_desktop.sh
```

### 2. Reboot Your System

```bash
sudo reboot
```

### 3. Complete Chrome Remote Desktop Setup

1. Open Google Chrome
2. Go to [https://remotedesktop.google.com/headless](https://remotedesktop.google.com/headless)
3. Click "Begin" and follow the authorization steps
4. Copy and run the provided command in your terminal
5. Set a PIN for remote access

### 4. Test Your Setup

```bash
# Test audio configuration
~/bin/test-audio.sh

# Check Chrome Remote Desktop status
~/bin/check-crd.sh
```

## What Gets Installed

### Core Components
- **Google Chrome** (required for Chrome Remote Desktop)
- **Chrome Remote Desktop** service
- **OpenBox** window manager
- **X11** display server
- **PulseAudio** for audio support

### Desktop Environment
- **OpenBox** - Lightweight window manager
- **Tint2** - System tray and taskbar
- **Thunar** - File manager
- **Firefox** - Web browser
- **XTerm** - Terminal emulator
- **Nitrogen** - Wallpaper manager
- **LXAppearance** - Theme configuration
- **Pavucontrol** - Audio control panel

### Audio System
- **PulseAudio** - Audio server
- **ALSA utilities** - Audio drivers
- **Audio streaming modules** for remote desktop

## Configuration Files

The installation creates several configuration files:

```
~/.chrome-remote-desktop-session    # Main session script
~/.config/openbox/                  # OpenBox configuration
~/.config/pulse/                    # PulseAudio configuration
~/.config/tint2/                    # System tray configuration
~/bin/                              # Helper scripts
```

## Helper Scripts

After installation, you'll have these useful scripts in `~/bin/`:

### `test-audio.sh`
Tests audio configuration and playback:
```bash
~/bin/test-audio.sh
```

### `fix-audio.sh`
Fixes common audio issues:
```bash
~/bin/fix-audio.sh
```

### `check-crd.sh`
Shows Chrome Remote Desktop status:
```bash
~/bin/check-crd.sh
```

### `restart-crd.sh`
Restarts Chrome Remote Desktop service:
```bash
~/bin/restart-crd.sh
```

## Audio Configuration Script

For advanced audio configuration and troubleshooting:

```bash
# Download the audio configuration script
wget https://raw.githubusercontent.com/arifbdarsono/crd-openbox-setup/main/configure_audio_crd.sh

# Make it executable
chmod +x configure_audio_crd.sh

# Run with menu
./configure_audio_crd.sh

# Or run specific functions
./configure_audio_crd.sh status    # Show audio status
./configure_audio_crd.sh test      # Test audio
./configure_audio_crd.sh fix       # Fix audio issues
./configure_audio_crd.sh optimize  # Optimize for remote desktop
./configure_audio_crd.sh all       # Run all optimizations
```

## Desktop Usage

### Right-Click Menu
Right-click on the desktop to access the OpenBox menu with:
- Terminal
- File Manager
- Web Browser
- Audio Control
- Appearance Settings
- OpenBox Configuration

### Keyboard Shortcuts
- **Alt + F2** - Run command dialog (gmrun)
- **Alt + Tab** - Switch between windows
- **Ctrl + Alt + T** - Open terminal (if configured)

### System Tray
The bottom panel (tint2) provides:
- Window list/taskbar
- System tray for applications
- Clock display

## Troubleshooting

### Audio Issues

**Problem**: No audio in remote session
```bash
# Solution 1: Restart PulseAudio
~/bin/fix-audio.sh

# Solution 2: Manual restart
pulseaudio --kill
pulseaudio --start

# Solution 3: Check audio devices
pactl list short sinks
```

**Problem**: Audio is choppy or delayed
```bash
# Optimize audio configuration
./configure_audio_crd.sh optimize
```

### Connection Issues

**Problem**: Cannot connect to remote desktop
```bash
# Check service status
~/bin/check-crd.sh

# Restart service
~/bin/restart-crd.sh

# Check logs
journalctl --user -u chrome-remote-desktop -f
```

**Problem**: Black screen after connection
```bash
# Check if session script is executable
ls -la ~/.chrome-remote-desktop-session

# Restart X11 session
sudo systemctl restart chrome-remote-desktop@$USER
```

### Performance Issues

**Problem**: Slow remote desktop performance
1. Reduce screen resolution in Chrome Remote Desktop settings
2. Disable any visual effects
3. Close unnecessary applications

**Problem**: High CPU usage
1. Check for runaway processes: `htop`
2. Restart Chrome Remote Desktop service
3. Consider using another lighter desktop environment

## Advanced Configuration

### Custom Screen Resolutions

Edit `~/.chrome-remote-desktop-session` and modify:
```bash
export CHROME_REMOTE_DESKTOP_DEFAULT_DESKTOP_SIZES="1920x1080,1680x1050,1280x720"
```

### Custom Applications

Add applications to OpenBox autostart:
```bash
echo "your-application &" >> ~/.config/openbox/autostart
```

### Audio Quality Settings

Edit `~/.config/pulse/daemon.conf`:
```ini
default-sample-rate = 48000        # Higher quality
default-fragment-size-msec = 10    # Lower latency
```

## Limitations

- No hardware-accelerated graphics (software rendering only)
- Limited gaming performance
- Some applications may not work properly in remote session
- Audio latency depends on network connection quality

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues specific to this setup:
1. Check the troubleshooting section above
2. Run the diagnostic scripts
3. Check system logs: `journalctl --user -u chrome-remote-desktop`

For Chrome Remote Desktop issues:
- [Official Chrome Remote Desktop Help](https://support.google.com/chrome/answer/1649523)
- [Chrome Remote Desktop Community](https://support.google.com/chrome/community)

## Changelog

### v1.0.1 (2025-07-07)
- [Fix] Audio streaming fail to start when reboot or logout

### v1.0.0 (2025-07-07)
- Initial release

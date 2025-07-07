#!/bin/bash

# Chrome Remote Desktop Uninstall Script
# Removes Chrome Remote Desktop and related configurations

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Please run as a regular user with sudo privileges."
   exit 1
fi

echo -e "${RED}Chrome Remote Desktop Uninstall Script${NC}"
echo -e "${YELLOW}This will remove Chrome Remote Desktop and related configurations.${NC}"
echo
warn "This action cannot be undone!"
echo
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    info "Uninstall cancelled."
    exit 0
fi

log "Starting Chrome Remote Desktop uninstallation..."

# Stop Chrome Remote Desktop service
log "Stopping Chrome Remote Desktop service..."
sudo systemctl stop chrome-remote-desktop@$USER.service 2>/dev/null || true
sudo systemctl disable chrome-remote-desktop@$USER.service 2>/dev/null || true

# Remove Chrome Remote Desktop package
log "Removing Chrome Remote Desktop package..."
sudo apt remove --purge -y chrome-remote-desktop 2>/dev/null || true

# Remove Google Chrome (optional)
read -p "Do you want to remove Google Chrome as well? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Removing Google Chrome..."
    sudo apt remove --purge -y google-chrome-stable 2>/dev/null || true
    sudo rm -f /etc/apt/sources.list.d/google-chrome.list
fi

# Remove OpenBox and related packages (optional)
read -p "Do you want to remove OpenBox desktop environment? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Removing OpenBox desktop environment..."
    sudo apt remove --purge -y \
        openbox \
        obconf \
        obmenu \
        tint2 \
        nitrogen \
        thunar \
        lxappearance \
        gmrun \
        menu 2>/dev/null || true
fi

# Remove PulseAudio (optional)
read -p "Do you want to remove PulseAudio? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Removing PulseAudio..."
    sudo apt remove --purge -y \
        pulseaudio \
        pulseaudio-utils \
        pavucontrol 2>/dev/null || true
fi

# Remove configuration files
log "Removing configuration files..."

# Chrome Remote Desktop configurations
rm -f ~/.chrome-remote-desktop-session
rm -rf ~/.config/chrome-remote-desktop/
rm -rf ~/.chrome-remote-desktop/

# OpenBox configurations
read -p "Remove OpenBox configuration files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ~/.config/openbox/
    rm -rf ~/.config/tint2/
fi

# PulseAudio configurations
read -p "Remove PulseAudio configuration files? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf ~/.config/pulse/
    systemctl --user disable pulseaudio.service 2>/dev/null || true
    rm -f ~/.config/systemd/user/pulseaudio.service
fi

# Remove helper scripts
log "Removing helper scripts..."
rm -f ~/bin/restart-crd.sh
rm -f ~/bin/check-crd.sh
rm -f ~/bin/test-audio.sh
rm -f ~/bin/fix-audio.sh

# Remove desktop files
rm -f ~/Desktop/chrome-remote-desktop-setup.desktop

# Remove documentation
rm -f ~/chrome-remote-desktop-setup-info.txt

# Remove user from groups
log "Removing user from chrome-remote-desktop group..."
sudo deluser $USER chrome-remote-desktop 2>/dev/null || true

# Clean up packages
log "Cleaning up unused packages..."
sudo apt autoremove -y
sudo apt autoclean

# Remove temporary files
log "Removing temporary files..."
rm -f /tmp/chrome-remote-desktop_current_amd64.deb

log "Uninstallation completed successfully!"
info "You may want to reboot your system to ensure all changes take effect."

echo
echo -e "${GREEN}=== Uninstallation Summary ===${NC}"
echo -e "${BLUE}✓ Chrome Remote Desktop service stopped and removed${NC}"
echo -e "${BLUE}✓ Configuration files removed${NC}"
echo -e "${BLUE}✓ Helper scripts removed${NC}"
echo -e "${BLUE}✓ User removed from chrome-remote-desktop group${NC}"
echo -e "${BLUE}✓ Temporary files cleaned up${NC}"
echo
echo -e "${YELLOW}Note: Some packages may have been kept if they're used by other applications${NC}"
echo -e "${YELLOW}Reboot recommended to complete the removal process${NC}"
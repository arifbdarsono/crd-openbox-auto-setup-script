#!/bin/bash

# Chrome Remote Desktop Setup Launcher
# One-command installation and configuration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}Chrome Remote Desktop Setup for Ubuntu 20.04${NC}"
echo -e "${BLUE}=============================================${NC}"
echo
echo "This script will install and configure:"
echo "• Chrome Remote Desktop"
echo "• OpenBox desktop environment"
echo "• PulseAudio for remote audio streaming"
echo "• Helper scripts and troubleshooting tools"
echo

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}ERROR: This script should not be run as root.${NC}"
   echo "Please run as a regular user with sudo privileges."
   exit 1
fi

# Check Ubuntu version
if ! grep -q "20.04" /etc/os-release; then
    echo -e "${YELLOW}WARNING: This script tested on Ubuntu 20.04 only.${NC}"
    echo "Your system may not be compatible."
    read -p "Do you want to continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Show menu
echo -e "${GREEN}Available options:${NC}"
echo "1. Full installation (recommended)"
echo "2. Install Chrome Remote Desktop only"
echo "3. Configure audio only"
echo "4. Fix package compatibility issues"
echo "5. Validate existing installation"
echo "6. Uninstall Chrome Remote Desktop"
echo "7. Exit"
echo

read -p "Select an option (1-7): " choice

case $choice in
    1)
        echo -e "${GREEN}Starting full installation...${NC}"
        if [ -f "$SCRIPT_DIR/install_chrome_remote_desktop.sh" ]; then
            "$SCRIPT_DIR/install_chrome_remote_desktop.sh"
            echo
            echo -e "${BLUE}Running post-installation audio configuration...${NC}"
            if [ -f "$SCRIPT_DIR/configure_audio_crd.sh" ]; then
                "$SCRIPT_DIR/configure_audio_crd.sh" all
            fi
            echo
            echo -e "${BLUE}Validating installation...${NC}"
            if [ -f "$SCRIPT_DIR/validate_installation.sh" ]; then
                "$SCRIPT_DIR/validate_installation.sh"
            fi
        else
            echo -e "${RED}ERROR: Installation script not found!${NC}"
            exit 1
        fi
        ;;
    2)
        echo -e "${GREEN}Installing Chrome Remote Desktop only...${NC}"
        if [ -f "$SCRIPT_DIR/install_chrome_remote_desktop.sh" ]; then
            "$SCRIPT_DIR/install_chrome_remote_desktop.sh"
        else
            echo -e "${RED}ERROR: Installation script not found!${NC}"
            exit 1
        fi
        ;;
    3)
        echo -e "${GREEN}Configuring audio...${NC}"
        if [ -f "$SCRIPT_DIR/configure_audio_crd.sh" ]; then
            "$SCRIPT_DIR/configure_audio_crd.sh"
        else
            echo -e "${RED}ERROR: Audio configuration script not found!${NC}"
            exit 1
        fi
        ;;
    4)
        echo -e "${GREEN}Fixing package compatibility issues...${NC}"
        if [ -f "$SCRIPT_DIR/fix_package_issues.sh" ]; then
            "$SCRIPT_DIR/fix_package_issues.sh"
        else
            echo -e "${RED}ERROR: Package fix script not found!${NC}"
            exit 1
        fi
        ;;
    5)
        echo -e "${GREEN}Validating installation...${NC}"
        if [ -f "$SCRIPT_DIR/validate_installation.sh" ]; then
            "$SCRIPT_DIR/validate_installation.sh"
        else
            echo -e "${RED}ERROR: Validation script not found!${NC}"
            exit 1
        fi
        ;;
    6)
        echo -e "${YELLOW}Uninstalling Chrome Remote Desktop...${NC}"
        if [ -f "$SCRIPT_DIR/uninstall_chrome_remote_desktop.sh" ]; then
            "$SCRIPT_DIR/uninstall_chrome_remote_desktop.sh"
        else
            echo -e "${RED}ERROR: Uninstall script not found!${NC}"
            exit 1
        fi
        ;;
    7)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option. Please select 1-7.${NC}"
        exit 1
        ;;
esac

echo
echo -e "${GREEN}Setup completed!${NC}"
echo
echo -e "${BLUE}Next steps:${NC}"
echo "1. Reboot your system: sudo reboot"
echo "2. Open Chrome and visit: https://remotedesktop.google.com/headless"
echo "3. Follow the authorization steps"
echo "4. Test your remote connection"
echo
echo -e "${BLUE}Documentation:${NC}"
echo "• README.md - Complete documentation"
echo "• ~/chrome-remote-desktop-setup-info.txt - Setup summary"
echo
echo -e "${BLUE}Helper commands:${NC}"
echo "• ~/bin/test-audio.sh - Test audio"
echo "• ~/bin/check-crd.sh - Check status"
echo "• ~/bin/fix-audio.sh - Fix audio issues"
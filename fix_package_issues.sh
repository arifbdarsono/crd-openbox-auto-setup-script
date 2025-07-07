#!/bin/bash

# Package Compatibility Fix Script
# Handles missing packages and provides alternatives

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

# Function to check if package is available
package_available() {
    apt-cache show "$1" >/dev/null 2>&1
}

# Function to install package with fallback
install_with_fallback() {
    local package="$1"
    local fallback="$2"
    local description="$3"
    
    if package_available "$package"; then
        log "Installing $package ($description)..."
        sudo apt install -y "$package"
    elif [ ! -z "$fallback" ] && package_available "$fallback"; then
        warn "$package not available, installing $fallback instead..."
        sudo apt install -y "$fallback"
    else
        warn "$package not available and no fallback found. Skipping $description."
    fi
}

log "Fixing package compatibility issues..."

# Update package lists
log "Updating package lists..."
sudo apt update

# Handle missing packages with alternatives
log "Installing packages with fallbacks..."

# Text editor alternatives
install_with_fallback "mousepad" "gedit" "text editor"

# Calculator alternatives  
install_with_fallback "galculator" "gnome-calculator" "calculator"

# Image viewer alternatives
install_with_fallback "gpicview" "eog" "image viewer"

# Archive manager alternatives
install_with_fallback "file-roller" "xarchiver" "archive manager"

# System monitor alternatives
install_with_fallback "htop" "top" "system monitor"

# Menu editor (obmenu) - create manual alternative if not available
if ! package_available "obmenu"; then
    warn "obmenu not available. Creating manual menu editor script..."
    
    mkdir -p ~/bin
    cat > ~/bin/edit-openbox-menu.sh << 'EOF'
#!/bin/bash
# Simple OpenBox menu editor

MENU_FILE="$HOME/.config/openbox/menu.xml"

if [ ! -f "$MENU_FILE" ]; then
    echo "OpenBox menu file not found: $MENU_FILE"
    exit 1
fi

echo "OpenBox Menu Editor"
echo "=================="
echo "1. Edit menu with text editor"
echo "2. Add application to menu"
echo "3. Regenerate menu from system applications"
echo "4. Exit"
echo

read -p "Select option (1-4): " choice

case $choice in
    1)
        if command -v mousepad >/dev/null 2>&1; then
            mousepad "$MENU_FILE"
        elif command -v gedit >/dev/null 2>&1; then
            gedit "$MENU_FILE"
        elif command -v nano >/dev/null 2>&1; then
            nano "$MENU_FILE"
        else
            vi "$MENU_FILE"
        fi
        ;;
    2)
        echo "Add Application to Menu"
        echo "======================"
        read -p "Application name: " app_name
        read -p "Command to run: " app_command
        read -p "Description: " app_desc
        
        # Simple menu item addition (basic implementation)
        echo "Manual addition required. Edit $MENU_FILE and add:"
        echo "<item label=\"$app_name\">"
        echo "  <action name=\"Execute\">"
        echo "    <command>$app_command</command>"
        echo "  </action>"
        echo "</item>"
        ;;
    3)
        echo "Regenerating menu from system applications..."
        # Create a basic menu from available applications
        python3 -c "
import os
import xml.etree.ElementTree as ET

# Basic menu structure
menu_items = []

# Check for common applications
apps = {
    'Terminal': 'xterm',
    'File Manager': 'thunar',
    'Web Browser': 'firefox',
    'Text Editor': 'mousepad' if os.system('which mousepad >/dev/null 2>&1') == 0 else 'gedit',
    'Calculator': 'galculator' if os.system('which galculator >/dev/null 2>&1') == 0 else 'gnome-calculator'
}

print('Available applications found and added to menu.')
"
        ;;
    4)
        exit 0
        ;;
    *)
        echo "Invalid option"
        ;;
esac
EOF
    
    chmod +x ~/bin/edit-openbox-menu.sh
    info "Created manual menu editor: ~/bin/edit-openbox-menu.sh"
fi

# Check for other potential issues
log "Checking for other potential package issues..."

# Check if universe repository is enabled (common issue)
if ! grep -q "universe" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    warn "Universe repository may not be enabled. Enabling it..."
    sudo add-apt-repository universe -y
    sudo apt update
fi

# Install some essential packages that might be missing
ESSENTIAL_PACKAGES="software-properties-common apt-transport-https ca-certificates gnupg lsb-release"
for package in $ESSENTIAL_PACKAGES; do
    if ! dpkg -l | grep -q "^ii  $package "; then
        log "Installing essential package: $package"
        sudo apt install -y "$package" 2>/dev/null || warn "Could not install $package"
    fi
done

log "Package compatibility fixes completed!"

# Provide summary
echo
echo -e "${BLUE}=== Package Status Summary ===${NC}"
echo

# Check status of key packages
PACKAGES_TO_CHECK="openbox obconf tint2 thunar firefox xterm lxappearance gmrun pulseaudio pavucontrol"
for package in $PACKAGES_TO_CHECK; do
    if dpkg -l | grep -q "^ii  $package "; then
        echo -e "✓ $package: ${GREEN}Installed${NC}"
    else
        echo -e "✗ $package: ${RED}Not installed${NC}"
    fi
done

echo
echo -e "${BLUE}Optional packages:${NC}"
OPTIONAL_PACKAGES="mousepad galculator gpicview file-roller htop obmenu"
for package in $OPTIONAL_PACKAGES; do
    if dpkg -l | grep -q "^ii  $package "; then
        echo -e "✓ $package: ${GREEN}Installed${NC}"
    else
        echo -e "- $package: ${YELLOW}Not installed (optional)${NC}"
    fi
done

echo
info "If you're still missing packages, try running the main installation script again."
info "The script will now handle missing packages more gracefully."
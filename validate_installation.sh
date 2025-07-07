#!/bin/bash

# Chrome Remote Desktop Installation Validation Script
# Checks if all components are properly installed and configured

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test results
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="$3"
    
    echo -n "Testing $test_name... "
    
    if eval "$test_command" >/dev/null 2>&1; then
        if [ "$expected_result" = "pass" ]; then
            echo -e "${GREEN}PASS${NC}"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}FAIL${NC} (expected to fail but passed)"
            ((TESTS_FAILED++))
        fi
    else
        if [ "$expected_result" = "fail" ]; then
            echo -e "${GREEN}PASS${NC} (expected to fail)"
            ((TESTS_PASSED++))
        else
            echo -e "${RED}FAIL${NC}"
            ((TESTS_FAILED++))
        fi
    fi
}

# Function to check file exists
check_file() {
    local file_path="$1"
    local description="$2"
    
    echo -n "Checking $description... "
    
    if [ -f "$file_path" ]; then
        echo -e "${GREEN}EXISTS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}MISSING${NC}"
        ((TESTS_FAILED++))
    fi
}

# Function to check directory exists
check_directory() {
    local dir_path="$1"
    local description="$2"
    
    echo -n "Checking $description... "
    
    if [ -d "$dir_path" ]; then
        echo -e "${GREEN}EXISTS${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}MISSING${NC}"
        ((TESTS_FAILED++))
    fi
}

echo -e "${BLUE}=== Chrome Remote Desktop Installation Validation ===${NC}"
echo

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}ERROR: This script should not be run as root.${NC}"
   exit 1
fi

echo -e "${YELLOW}1. Checking Required Packages${NC}"
run_test "Google Chrome" "command -v google-chrome" "pass"
run_test "Chrome Remote Desktop" "dpkg -l | grep chrome-remote-desktop" "pass"
run_test "OpenBox" "command -v openbox" "pass"
run_test "PulseAudio" "command -v pulseaudio" "pass"
run_test "Tint2" "command -v tint2" "pass"
run_test "Thunar" "command -v thunar" "pass"
echo

echo -e "${YELLOW}2. Checking Configuration Files${NC}"
check_file "$HOME/.chrome-remote-desktop-session" "Chrome Remote Desktop session script"
check_directory "$HOME/.config/openbox" "OpenBox configuration directory"
check_file "$HOME/.config/openbox/autostart" "OpenBox autostart script"
check_file "$HOME/.config/openbox/menu.xml" "OpenBox menu configuration"
check_directory "$HOME/.config/pulse" "PulseAudio configuration directory"
check_file "$HOME/.config/pulse/default.pa" "PulseAudio configuration"
check_directory "$HOME/.config/tint2" "Tint2 configuration directory"
check_file "$HOME/.config/tint2/tint2rc" "Tint2 configuration file"
echo

echo -e "${YELLOW}3. Checking Helper Scripts${NC}"
check_directory "$HOME/bin" "Helper scripts directory"
check_file "$HOME/bin/restart-crd.sh" "Chrome Remote Desktop restart script"
check_file "$HOME/bin/check-crd.sh" "Chrome Remote Desktop status script"
echo

echo -e "${YELLOW}4. Checking File Permissions${NC}"
run_test "Chrome Remote Desktop session script executable" "[ -x '$HOME/.chrome-remote-desktop-session' ]" "pass"
run_test "OpenBox autostart script executable" "[ -x '$HOME/.config/openbox/autostart' ]" "pass"
if [ -f "$HOME/bin/restart-crd.sh" ]; then
    run_test "Helper scripts executable" "[ -x '$HOME/bin/restart-crd.sh' ]" "pass"
fi
echo

echo -e "${YELLOW}5. Checking Services${NC}"
run_test "Chrome Remote Desktop service exists" "systemctl --user list-unit-files | grep chrome-remote-desktop" "pass"
run_test "User in chrome-remote-desktop group" "groups | grep chrome-remote-desktop" "pass"
echo

echo -e "${YELLOW}6. Checking Audio System${NC}"
run_test "PulseAudio running" "pulseaudio --check" "pass"
run_test "Audio devices available" "pactl list short sinks | grep -q ." "pass"
echo

echo -e "${YELLOW}7. Checking Desktop Environment${NC}"
run_test "X11 available" "command -v X" "pass"
run_test "Display server tools" "command -v xrandr" "pass"
echo

# Summary
echo -e "${BLUE}=== Validation Summary ===${NC}"
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed! Your Chrome Remote Desktop installation appears to be complete.${NC}"
    echo
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Reboot your system if you haven't already"
    echo "2. Open Chrome and go to: https://remotedesktop.google.com/headless"
    echo "3. Follow the setup instructions to authorize your computer"
    echo "4. Test your remote connection"
    echo
    echo -e "${BLUE}Troubleshooting tools:${NC}"
    echo "- Test audio: ~/bin/test-audio.sh"
    echo "- Check status: ~/bin/check-crd.sh"
    echo "- Fix issues: ~/bin/fix-audio.sh"
else
    echo -e "${RED}✗ Some tests failed. Please review the installation.${NC}"
    echo
    echo -e "${BLUE}Common solutions:${NC}"
    echo "1. Re-run the installation script"
    echo "2. Check for error messages in the installation log"
    echo "3. Ensure you have sudo privileges"
    echo "4. Verify internet connectivity"
    echo
    echo -e "${BLUE}For help:${NC}"
    echo "- Check the README.md file"
    echo "- Review system logs: journalctl --user -u chrome-remote-desktop"
fi

exit $TESTS_FAILED
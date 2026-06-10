#!/bin/bash

# Token-based installer for the Insight Agent on macOS (Intel & Apple Silicon)

# Prevent "tput: No value for $TERM" errors in headless environments
export TERM=xterm

# --- CONFIGURATION ---
# Fetching variables from Jamf Pro Parameters
# Parameter 4 ($4) = Tags (e.g., "Production,Workstation")
# Parameter 5 ($5) = Token (e.g., "us:InsertYourTokenHere")

TAGS="$4"
TOKEN="$5"

# Validation: Ensure parameters 4 and 5 are actually populated
if [ -z "$TAGS" ] || [ -z "$TOKEN" ]; then
    echo "Error: TAGS (Parameter 4) or TOKEN (Parameter 5) is missing."
    echo "Please ensure both parameters are populated in the Jamf Pro policy."
    exit 1
fi

# Create a temporary working directory to keep Jamf execution clean
WORKDIR=$(mktemp -d)
cd "$WORKDIR" || exit 1

# --- ARCHITECTURE DETECTION & DOWNLOAD ---
ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    echo "Detected Intel (x86_64) architecture. Setting download URL..."
    DOWNLOAD_URL="https://s3.amazonaws.com/com.rapid7.razor.public/endpoint/agent/latest/darwin/x86_64/agent_control_latest_x64.sh"
elif [ "$ARCH" = "arm64" ]; then
    echo "Detected Apple Silicon (arm64) architecture. Setting download URL..."
    DOWNLOAD_URL="https://s3.amazonaws.com/com.rapid7.razor.public/endpoint/agent/latest/darwin/arm64/agent_control_latest_arm64.sh"
else
    echo "Error: Unsupported architecture: $ARCH"
    exit 1
fi

echo "Downloading Rapid7 installer..."
curl -s "$DOWNLOAD_URL" > agent_installer.sh

# Make the script executable
chmod +x agent_installer.sh

# --- INSTALL, CONFIGURE, AND START ---
echo "Installing, configuring, and starting Rapid7..."
# The 'reinstall_start' flag natively handles laying down the files, 
# applying the Token/Tags for configuration, and booting the service.
./agent_installer.sh reinstall_start --token "$TOKEN" --attributes "$TAGS"

echo "Checking installed version..."
./agent_installer.sh version

# --- VERIFICATION & MANUAL START ---
echo "Verifying Rapid7 is actively running..."
# This checks macOS launchd to ensure the Rapid7 daemon is loaded and running
if launchctl list | grep -q "com.rapid7.ir_agent"; then
    echo "Success: com.rapid7.ir_agent is running in launchctl."
else
    echo "Warning: com.rapid7.ir_agent is not running. Attempting to start the service manually..."
    launchctl start com.rapid7.ir_agent
    
    # Give the service a couple of seconds to boot up, then check one last time
    sleep 2
    if launchctl list | grep -q "com.rapid7.ir_agent"; then
        echo "Success: com.rapid7.ir_agent was successfully started manually."
    else
        echo "Error: com.rapid7.ir_agent failed to start after manual attempt. Please check system logs."
    fi
fi

# --- CLEANUP ---
echo "Cleaning up temporary files..."
rm -rf agent_installer.sh cafile.pem client.crt client.key config.json

# Remove the temporary working directory
cd /tmp || exit
rm -rf "$WORKDIR"

echo "Installation complete."
exit 0
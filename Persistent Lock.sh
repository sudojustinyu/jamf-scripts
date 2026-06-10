#!/bin/bash

# --- Configuration ---
L_DIR="/Library/Application Support/SaksGlobal"
L_SCRIPT="$L_DIR/lockscreen.sh"
PLIST_PATH="/Library/LaunchAgents/com.saks.compliance.lock.plist"

TITLE="COMPLIANCE VIOLATION"
HEADING="This computer has been locked by Saks Global"
DESC="This system is owned by Saks Global and is not currently in compliance. \n\nPlease reach out to Workplace Services or ship to Saks Global at 225 Liberty St, Floor 27, New York NY 10007."
HELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
ICON="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/Lock.jpg"

# 1. Create the support directory
mkdir -p "$L_DIR"

# 2. Create the local lock script
# This script is what the LaunchAgent will actually run.
cat << 'EOF' > "$L_SCRIPT"
#!/bin/bash
HELPER="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
TITLE="COMPLIANCE VIOLATION"
HEADING="This computer has been locked by Saks Global"
DESC="This system is owned by Saks Global and is not currently in compliance.

Please reach out to Workplace Services or ship to Saks Global at 225 Liberty St, Floor 27, New York NY 10007."
ICON="/System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/Lock.jpg"

# Dim the background using the ARD Lock screen
/System/Library/CoreServices/RemoteManagement/AppleVNCServer.bundle/Contents/Support/LockScreen.app/Contents/MacOS/LockScreen &

# Launch jamfHelper in the foreground
"$HELPER" -windowType fs -title "$TITLE" -heading "$HEADING" -description "$DESC" -icon "$ICON" -alignHeading center -alignDescription center -lockHUD
EOF

chmod +x "$L_SCRIPT"

# 3. Create the LaunchAgent Plist
# The 'KeepAlive' key ensures that if the process dies, it restarts immediately.
cat << EOF > "$PLIST_PATH"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.saks.compliance.lock</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$L_SCRIPT</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF

# 4. Set correct permissions
chown root:wheel "$PLIST_PATH"
chmod 644 "$PLIST_PATH"

# 5. Load the Agent for the current logged-in user
CURRENT_USER=$(stat -f%Su /dev/console)
USER_ID=$(id -u "$CURRENT_USER")

if [ "$CURRENT_USER" != "root" ]; then
    echo "Loading agent for user: $CURRENT_USER"
    launchctl bootstrap gui/"$USER_ID" "$PLIST_PATH"
fi

echo "Lockdown initiated."
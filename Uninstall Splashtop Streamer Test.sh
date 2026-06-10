#!/bin/bash

################################################################################
# Master Splashtop Uninstaller Script
# Targeted Fixes: Shutdown stalls (SRStreamerDaemon), LSD Faults, and Driver Remnants after Island Protect install.
################################################################################

# 1. Identify Environment
# We identify the console user to perform logout and TCC resets in their context.
currentUser=$(stat -f '%Su' /dev/console)
echo "Executing uninstallation for current user: $currentUser"

# Package receipts to forget (to resolve LSD 'unknown architecture' faults).
PKG_LIST=(
    "com.splashtop.splashtopStreamer.com.splashtop.streamer-daemon.pkg"
    "com.splashtop.splashtopStreamer.com.splashtop.streamer-for-user.pkg"
    "com.splashtop.splashtopStreamer.com.splashtop.streamer-srioframebuffer.pkg"
    "com.splashtop.splashtopStreamer.postflight.pkg"
    "com.splashtop.splashtopStreamer.SplashtopStreamer.pkg"
    "com.splashtop.splashtopStreamer.com.splashtop.streamer-for-root.pkg"
    "com.splashtop.Splashtop-Streamer"
)

# Bundle IDs used for TCC database resets[cite: 8].
BUNDLE_IDS=("com.splashtop.Splashtop-Streamer" "com.splashtop.streamer-daemon")

# 2. Reset TCC Privacy Permissions
# This clears corrupted entries in the privacy database that cause LSD faults.
echo "Resetting TCC privacy permissions..."
TCC_SERVICES=("ScreenCapture" "Accessibility" "PostEvent" "SystemPolicyAllFiles")
for BUNDLE_ID in "${BUNDLE_IDS[@]}"; do
    for SERVICE in "${TCC_SERVICES[@]}"; do
        # We run this as root to affect the system-wide database for this bundle ID.
        /usr/bin/tccutil reset "$SERVICE" "$BUNDLE_ID" 2>/dev/null
    done
done

# 3. User-Context Graceful Logout
# Even if the user isn't an admin, we must impersonate them to reach their session.
if [ -d "/Applications/Splashtop Streamer.app" ] && [ "$currentUser" != "root" ]; then
    echo "Attempting graceful logout for $currentUser..."
    # 'sudo -u' allows the root-level Jamf script to trigger the user's app instance.
    sudo -u "$currentUser" open "st-streamer://com.splashtop.streamer?logout=1" 2>/dev/null
    sleep 4 
fi

# 4. Force Terminate Processes
# These specific processes were identified as the cause of shutdown stalls.
echo "Stopping all Splashtop processes..."
PROCESS_LIST=("inputserv" "spupnp" "SRProxy" "SRFeature" "SplashtopRemote" "SRIOFrameBuffer" "Splashtop Streamer" "SRStreamerDaemon")
for proc in "${PROCESS_LIST[@]}"; do
    # Force kill (-9) is used if the process ignores the standard termination signal.
    /usr/bin/killall "$proc" 2>/dev/null || /usr/bin/killall -9 "$proc" 2>/dev/null
done

# 5. Unload and Delete Launchctl Services
# Unloading these prevents the 'XPC timeout' hangs seen in your spindump logs.
echo "Unloading background services..."
PLISTS=(
    "/Library/LaunchAgents/com.splashtop.streamer.SRServiceAgent.plist"
    "/Library/LaunchAgents/com.splashtop.streamer.plist"
    "/Library/LaunchDaemons/com.splashtop.streamer-daemon.plist"
    "/Library/LaunchDaemons/com.splashtop.streamer-srioframebuffer.plist"
    "/Library/LaunchDaemons/com.splashtop-streamer.usbhelper.plist"
)
for plist in "${PLISTS[@]}"; do
    if [ -f "$plist" ]; then
        /bin/launchctl unload "$plist" 2>/dev/null
        /bin/rm -f "$plist"
    fi
done

# 6. Driver and Kernel Extension Removal
# Crucial for system stability on macOS 15.x.
echo "Removing drivers and kernel extensions..."
/bin/rm -rf "/Library/Audio/Plug-Ins/HAL/SplashtopRemoteSound.driver"
/bin/rm -rf "/Library/Audio/Plug-Ins/HAL/SplashtopRemoteMic.driver"
/bin/rm -rf "/Library/Extensions/SRXFrameBufferConnector.kext"
/bin/rm -rf "/Library/Extensions/SRXDisplayCard.kext"

# Kickstart coreaudio to stop it from looking for the deleted drivers.
/usr/bin/launchctl kickstart -kp system/com.apple.audio.coreaudiod 2>/dev/null

# 7. Final Cleanup and Package Forgetting
# This ensures LSD and Jamf Inventory reflect a clean state.
echo "Performing final file cleanup..."
FILES_TO_REMOVE=(
    "/Applications/Splashtop Streamer.app"
    "/Library/Application Support/Splashtop Streamer"
    "/Users/Shared/SplashtopStreamer"
    "/Users/$currentUser/Library/Application Support/Splashtop Streamer"
)
for file in "${FILES_TO_REMOVE[@]}"; do
    /bin/rm -rf "$file" 2>/dev/null
done

# Forget all package history to stop LSD from scanning corrupted architectures.
for pkg in "${PKG_LIST[@]}"; do
    /usr/sbin/pkgutil --forget "$pkg" 2>/dev/null
done

echo "Uninstallation complete"
exit 0
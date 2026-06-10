#!/bin/bash

# --- CONFIGURATION ---
# If you have an Uninstall/Tamper Protection password set in the Zscaler portal, 
# enter it in script option Parameter 4
UNINSTALL_PASSWORD="$4"
# ---------------------

target_path="/Applications/Zscaler/.Uninstaller.sh"

if [ ! -e "$target_path" ]; then
    echo "Zscaler not found at: $target_path"
    echo "Nothing to uninstall."
    exit 0 
else
    echo "Zscaler found at: $target_path"
    echo "Attempting uninstall..."

    # Check if a password was provided in the configuration variable
    if [ -n "$UNINSTALL_PASSWORD" ]; then
        # Run with password argument
        /bin/sh "$target_path" --password "$UNINSTALL_PASSWORD"
    else
        # Run standard uninstall
        /bin/sh "$target_path"
    fi

    # Exit with success immediately after running the command
    exit 0
fi
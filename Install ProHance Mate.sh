#!/bin/bash

# Define the package path
PACKAGE_PATH="/private/tmp/ProHance/ProHanceMate_Installer_9.8.3.254.pkg"

# Check if the package file exists
if [ -f "$PACKAGE_PATH" ]; then
    echo "Package file found at $PACKAGE_PATH"
else
    echo "Package file not found at $PACKAGE_PATH"
    exit 1
fi

# Install the package
sudo installer -pkg "$PACKAGE_PATH" -target /

# Check the installation status
INSTALL_STATUS=$?
if [ "$INSTALL_STATUS" -eq 0 ]; then
    echo "Package installation successful"
else
    echo "Package installation failed"
fi

exit "$INSTALL_STATUS"


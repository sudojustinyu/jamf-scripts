#!/bin/bash

# Download the latest YAML file for Hue version number
curl -o /tmp/hueversion.yml https://download.creativeforce.io/released-files.042024/prod/hue-uxp/mac/latest-mac.yml

# Path to YAML file
yaml_file="/tmp/hueversion.yml"

# Get the version from the YAML file
version_yaml=$(awk '/^version:/ {print $2}' "$yaml_file")

if [ -z "$version_yaml" ]; then
    echo "Version information not found in the YAML file"
else
    echo "The version is $version_yaml"
fi

# Set the path to the application
app_path="/Applications/Hue.app"

# Get the current installed version
version_app=$(defaults read "$app_path/Contents/Info.plist" CFBundleShortVersionString 2>/dev/null)

if [ -z "$version_app" ]; then
    echo "Application is not installed or the path is incorrect"
else
    echo "The version of Hue is $version_app"
fi

# Compare the versions
if [[ "$version_yaml" == "$version_app" ]]; then
    echo "The newest version is installed"
    exit 0
else
    echo "The newest version is not installed"
fi

# Close the application if it's running
if pgrep "Hue" > /dev/null; then
    echo "Closing Hue application..."
    sudo killall "Hue"
    sleep 2 # Add a brief pause to ensure the app is fully closed
fi

# Installing the newest version
echo "Installing the newest version"

# Construct the new URL using the new version number
url="https://download.creativeforce.io/released-files.042024/prod/hue-uxp/mac/Hue-$version_yaml-mac.pkg"

# Download the Hue package
curl "$url" -o /tmp/installer.pkg

# Set correct permissions
sudo chmod 755 /tmp/installer.pkg

# Install the package using sudo
sudo installer -pkg /tmp/installer.pkg -target /

exit 0

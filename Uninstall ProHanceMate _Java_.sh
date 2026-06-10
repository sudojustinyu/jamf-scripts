#!/bin/bash

# Run the cleanup script
sudo /Applications/ProHanceMate/installer/executables/uninstallprobe.sh -s

# Check if the file exists before attempting to remove it
if [ -f "/private/var/root/prohance.mv.db" ]; then
  # Remove the file with sudo privileges
  sudo rm "/private/var/root/prohance.mv.db"
  echo "Successfully removed /private/var/root/prohance.mv.db"
else
  echo "File /private/var/root/prohance.mv.db does not exist."
fi

# Check if the ProHance application exists before attempting to remove it
if [ -d "/Applications/ProHance.app" ]; then
  sudo rm -rf "/Applications/ProHance.app"
  echo "Successfully removed /Applications/ProHance.app"
else
  echo "File /Applications/ProHance.app does not exist."
fi
# Check if the ProHanceMate folder exists before attempting to remove it
if [ -d "/Applications/ProHanceMate" ]; then
  sudo rm -rf "/Applications/ProHanceMate"
  echo "Successfully removed /Applications/ProHanceMate"
else
  echo "File /Applications/ProHanceMate does not exist."
fi

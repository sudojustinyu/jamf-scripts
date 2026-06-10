#!/bin/bash

# Ensure the cleanup script is executable
sudo chmod +x /Applications/ProHance.app/Contents/Library/scripts/cleanup.sh

# Run the cleanup script
sudo /Applications/ProHance.app/Contents/Library/scripts/cleanup.sh

# Check if the ProHance database file exists before attempting to remove it
if [ -f "/private/var/root/prohance.mv.db" ]; then
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

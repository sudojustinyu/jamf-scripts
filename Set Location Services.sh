#!/bin/sh
sudo defaults write /var/db/locationd/Library/Preferences/ByHost/com.apple.locationd LocationServicesEnabled -int 1


# Setting time zone automatically
/usr/bin/defaults write /Library/Preferences/com.apple.timezone.auto Active -bool TRUE
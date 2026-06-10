#!/bin/bash

### Script to fully remove Google Chrome

loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )

## Closing App
echo "Quitting Chrome"
killall -9 "Google Chrome"

sleep 1

## Remove App From Apps Folder
echo "Removing Chrome Files"
rm -rf /Applications/Google\ Chrome.app/
rm /Library/LaunchAgents/com.google.keystone*
rm -rf /Library/Application\ Support/Google/Chrome
rm /Users/${loggedInUser}/Library/Preferences/com.google.Chrome*

rm -rf /Users/${loggedInUser}/Applications/Chrome\ Apps.localized/
rm /Users/${loggedInUser}/Library/LaunchAgents/com.google.keystone*
rm -rf /Users/${loggedInUser}/Library/Application\ Support/Google/Chrome
rm /Users/${loggedInUser}/Library/Preferences/com.google.Chrome*
rm -rf /Users/${loggedInUser}/Library/Application\ Support/CrashReporter/Google\ Chrome
rm /Users/${loggedInUser}/Library/Preferences/Google\ Chrome*
rm -r /Users/${loggedInUser}/Library/Caches/com.google.Chrome*
rm -r /Users/${loggedInUser}/Library/Saved\ Application\ State/com.google.Chrome.savedState/
rm /Users/${loggedInUser}/Library/Google/GoogleSoftwareUpdate/Actives/com.google.Chrome
rm /Users/${loggedInUser}/Library/Google/Google\ Chrome*

exit 0
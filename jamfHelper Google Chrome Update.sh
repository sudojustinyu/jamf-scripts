#!/bin/bash

# Google Chrome Update Reminder.

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
-windowType utility \
-lockHUD \
-title "Saks Tech Services - Google Chrome Update" \
-heading "Please follow the directions below to update your Google Chrome app." \
-description "On your Mac, open Chrome if it is not opened. At the top right, click More. Click Help > About Google Chrome. Click Update Google Chrome. Important: If you can't find this button, you're on the latest version. Click Relaunch." \
-button1 "Acknowledge" \

exit 0
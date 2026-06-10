#!/bin/bash

# macOS Upgrade Reminder.

/Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
-windowType utility \
-lockHUD \
-title "Saks Tech Services - macOS Monterey Upgrade" \
-heading "Reminder: Please run Upgrade macOS Monterey in Saks Self Service" \
-description "At the end of your workday, please run \"Upgrade to macOS Monterey\" from the Self Service app in the Applications folder. This process will take about an hour and your computer may restart multiple times. Leave your computer connected to power and do not move or close your laptop." \
-button1 "Acknowledge" \

exit 0
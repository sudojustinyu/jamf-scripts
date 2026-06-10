#!/bin/bash
DARWIN_MAJOR_VERSION="$(uname -r | cut -d '.' -f 1)" # 17 = 10.13, 18 = 10.14, 19 = 10.15, 20 = 11.0, etc.
readonly DARWIN_MAJOR_VERSION
if (( DARWIN_MAJOR_VERSION == 21 )); then
notification_center_Enable_all_flags='41951310' # macOS Monterey
elif (( DARWIN_MAJOR_VERSION == 22 )); then
notification_center_Enable_all_flags='41951310' # macOS Ventura
fi
CURRENT_USER=$(/usr/bin/stat -f "%Su" /dev/console)
CURRENT_USER_ID=$(id -u $CURRENT_USER)
launchctl asuser "${CURRENT_USER_ID}" sudo -u "${CURRENT_USER}" defaults write 'com.apple.ncprefs' apps -array-add "<dict><key>bundle-id</key><string>com.tinyspeck.slackmacgap</string><key>flags</key><integer>${notification_center_Enable_all_flags}</integer><key>path</key><string>/Applications/Slack.app</string></dict>"
killall sighup usernoted
killall sighup NotificationCenter
echo "Slack Notifications have been set"
exit 0

#!/bin/zsh

# Policy names and policy triggers separated by ","

policyList="Getting ready,speed
Getting ready.,remove-apps
Getting ready...,ps-rename
Installing AV,crowdstrike
Log into Chrome with your Saks account to backup your bookmarks and settings,googlechrome
Use Zoom to meet with your team and join the company all-hands,zoom
Reach out to IT by clicking on the Jira tile in Okta,rosetta
You can use Slack to quickly connect with your co-workers,slack
Reach out to your PBP for any questions about benefits,splashtop
Installing Capture One,captureone
Installing Adobe Creative Cloud,adobecreativecloud
Installing Box Sync,boxsync
Installing Wacom Drivers,wacomdrivers
Installing Spotify,spotify
Installing Microsoft Office,office
Installing Jamf Connect,jamfconnect
Use Printer Logic to add printers when you are in the office,printer-logic
Head over to saks.okta.com for access to different apps,cyberark
Use Zscaler to connect to internal resources,zscaler
Downloading some files,saks-branding
Setting Login Icon,loginicon
Setting Wallpaper,desktoppr
Setting Dock,saksdock"
sudo authchanger -reset

# Provide path to jamfHelper
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

# wait until the Dock process has started
while [[ "$setupProcess" = "" ]]
do
	echo "Waiting for Dock"
	setupProcess=$( /usr/bin/pgrep "Dock" )
	sleep 10
done

# run policies
while IFS= read -r aPolicy
do
	policy=$( echo "$aPolicy" | /usr/bin/awk -F "," '{ print $1 }' )
	trigger=$( echo "$aPolicy" | /usr/bin/awk -F "," '{ print $2 }' )
	"$jamfHelper" -windowType fs -heading "Welcome to Saks!" -description "$policy" -icon /System/Library/CoreServices/Certificate\ Assistant.app/Contents/Resources/AppIcon.icns &
	/usr/local/bin/jamf policy -event "$trigger"
	logresult "Success: $policy" "Fail: $policy"
done <<< "$policyList"

# popup

jamf displayMessage -message "Please log back in and Enable FileVault."
sleep 3

/usr/bin/sudo /usr/bin/killall loginwindow

exit 0
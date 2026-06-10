#!/bin/zsh

# Policy names and policy triggers separated by ","

policyList="Please wait...,recon
Preparing your new Saks MacBook,sakslogo
Preparing your new Saks MacBook,rename
Contact us at helpme.it@saks.com,zoom
Use the Self Service app to install Saks applications and printers,googlechrome
Use the Self Service app to install Saks applications and printers,slack
Installing more applications...,saksdock
Use the Self Service app to install Saks applications and printers,loginicon
"

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
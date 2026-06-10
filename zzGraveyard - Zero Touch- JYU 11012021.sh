#!/bin/zsh

# Policy names and policy triggers separated by ","

policyList="Preparing your new Saks MacBook,wallpaper
Preparing your new Saks MacBook,rename
Contact us at helpme.it@saks.com,crowdstrike
Preparing your new Saks MacBook,jumpcloud
Contact us at helpme.it@saks.com,zoom
Installing applications...,googlechrome
Installing more applications...,slack
Use the Self Service app to install Saks applications,saksdock
Use the Self Service app to install Saks applications,hidejumpcloud
Almost done,recon"


# Set variables

logFile="/var/log/Provisioning.log"

function logresult()	{
	if [ $? = 0 ] ; then
	  /bin/date "+%Y-%m-%d %H:%M:%S	$1" >> "$logFile"
	  echo "$1" # for the policy log
	else
	  /bin/date "+%Y-%m-%d %H:%M:%S	$2" >> "$logFile"
	  echo "$2" # for the policy log
	fi
}

# Create log file
/usr/bin/touch $logFile

# Provide path to jamfHelper
jamfHelper="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"

# wait until the Dock process has started
while [[ "$setupProcess" = "" ]]
do
	echo "Waiting for Dock"
	setupProcess=$( /usr/bin/pgrep "Dock" )
	sleep 3
done

sleep 3

# get currently logged in user
currentUser=$( /usr/bin/stat -f "%Su" /dev/console )

echo "Current user is $currentUser"

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

jamf displayMessage -message "Please log back in and enable FileVault."
sleep 2

/usr/bin/sudo /usr/bin/killall loginwindow

exit 0
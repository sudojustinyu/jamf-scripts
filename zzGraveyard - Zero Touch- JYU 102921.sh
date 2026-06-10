#!/bin/zsh


<<'ABOUT_THIS_SCRIPT'
-----------------------------------------------------------------------
	
	Purpose: Runs when called by a Jamf Pro policy triggered
	by Enrollment Complete.
	1. Prompts user to enter asset tag.
	2. Runs specified policies by trigger name.
	3. Updates inventory.
	4. Restarts computer.
	
	Instructions: Add this script to Jamf Pro and then add it to a new
	Jamf Pro policy triggered by Enrollment Complete. This should be the
	only policy triggered by Enrollment Complete. Edit the $policyList
	below with policy names and policy triggers separated by a comma.
	
-----------------------------------------------------------------------
ABOUT_THIS_SCRIPT


# Policy names and policy triggers separated by ","

policyList="Renaming your Saks Mac,rename
Crowdstrike,crowdstrike
Jumpcloud,jumpcloud
Zoom,zoom
Google Chrome,googlechrome
"


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
	"$jamfHelper" -windowType hud -heading "Preparing your Saks Mac" -description "$policy..." -icon /System/Library/CoreServices/Finder.app/Contents/Resources/Finder.icns &
	/usr/local/bin/jamf policy -event "$trigger"
	logresult "Success: $policy" "Fail: $policy"
done <<< "$policyList"

# popup
sleep 9
jamf displayMessage -message "Saks Macbook onboarding has been completed."

exit 0
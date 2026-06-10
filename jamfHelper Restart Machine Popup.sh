#!/bin/bash
loggedInUser=$( echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
# JAMF Helper Path
JAMFHelperPath="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
# JAMF Helper Title
JAMFHelperTitle="Restart"
# JAMF Helper Heading
JAMFHelperHeading="Reminder: Please Restart Your Machine"
# JAMF Helper Message
JAMFHelperMessage="You are receiving this message because your machine hasn’t been restarted in over 30 days.

Please restart your machine as soon as possible to avoid any performance issues.

Please also save your work and quit any open applications before restarting."

if [ -e "/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png" ]
   then
      JAMFHelperIcon="/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"
   else
      JAMFHelperIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns"
 fi

"$JAMFHelperPath" -windowType utility -title "$JAMFHelperTitle" \
-icon "$JAMFHelperIcon" -iconSize 128 -heading "$JAMFHelperHeading" -alignHeading left -description "$JAMFHelperMessage" \
-alignDescription left -button1 "OK"
if [[ "$buttonClicked" == "0" ]]; then
    echo "User acknowledged"
    jamf recon
fi


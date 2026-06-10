#!/bin/bash
loggedInUser=$( echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
# JAMF Helper Path
JAMFHelperPath="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
# JAMF Helper Title
JAMFHelperTitle="Saks Software Installation"
# JAMF Helper Heading
JAMFHelperHeading="Jamf Connect Installation"
# JAMF Helper Icon
JAMFHelperMessage="You are receiving this message because your 
laptop does NOT have Jamf Connect installed.

Please be sure to install the app to keep
your Okta and computer passwords in sync."

if [ -e "/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png" ]
   then
      JAMFHelperIcon="/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"
   else
      JAMFHelperIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns"
 fi
JCSelection ()
{
UserResponse=$("$JAMFHelperPath" -windowType utility -title "$JAMFHelperTitle" \
               -icon "$JAMFHelperIcon" -iconSize 128 -heading "$JAMFHelperHeading" -alignHeading center -description "$JAMFHelperMessage" \
               -alignDescription center -button1 "Install" -button2 "Not Now" -cancelButton 2 )
                ## This first condition accounts for the user selecting cancel or simply closing the window
                if [ $UserResponse == 2 ] || [ $UserResponse == 239 ]
                then
                   echo "User choose to defer"
                   exit 0
                elif [ $UserResponse == 0 ]
                then
                  echo "User choose to install Jamf Connect"
                  JCInstall
                fi
}
JCInstall ()
{
if [ $UserResponse == 0 ]; then
"$JAMFHelperPath" -windowType utility -title "$JAMFHelperTitle" \
-icon "$JAMFHelperIcon" -iconSize 128 -heading "$JamfHelperHeading" -alignHeading center -description "Jamf Connect is currently installing" \
-alignDescription center &
jamfHelperUID=$(pgrep jamfHelper)
disown $jamfHelperUID
sudo jamf policy -id 184
fi
sleep 1
killall jamfHelper
JCPrompt
}
JCPrompt ()
{
if [ -d "/Applications/Jamf\ Connect.app" ]; then
"$JAMFHelperPath" -windowType utility -title "$JAMFHelperTitle" \
-icon "$JAMFHelperIcon" -iconSize 128 -heading "$JamfHelperHeading" -alignHeading left -description "Jamf Connect has been installed please make sure to login to the application with your Okta credentials."  \
-alignDescription left -button1 "Ok" -timeout 120 
        if [[ "$userChoice" == "0" ]]; then
        #Open the Zscaler App
        open -a "/Applications/Jamf\ Connect.app"
        else
        #Open once more
        open "/Applications/Jamf\ Connect.app"
        fi
fi
}
JCSelection
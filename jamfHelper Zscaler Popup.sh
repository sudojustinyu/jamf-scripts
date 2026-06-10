#!/bin/bash
loggedInUser=$( echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
# JAMF Helper Path
JAMFHelperPath="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
# JAMF Helper Title
JAMFHelperTitle="Saks Software Installation"
# JAMF Helper Heading
JAMFHelperHeading="Zscaler Installation"
# JAMF Helper Icon
JAMFHelperMessage="You are receiving this message because your 
laptop does NOT have Zscaler installed.

Please be sure to install Zscaler here 
before Tuesday, June 7th.

If you do not install and log into Zscaler by 
Wednesday, June 1, you will have limited network access."
if [ -e "/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/app.icns" ]
   then
      JAMFHelperIcon="/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/app.icns"
   else
      JAMFHelperIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FinderIcon.icns"
 fi
ZscalerSelection ()
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
                  echo "User choose to install Zscaler"
                  ZscalerInstall
                fi
}
ZscalerInstall ()
{
if [ $UserResponse == 0 ]; then
"$JAMFHelperPath" -windowType utility -title "$JAMFHelperTitle" \
-icon "$JAMFHelperIcon" -iconSize 128 -heading "$JamfHelperHeading" -alignHeading center -description "Zscaler is currently installing" \
-alignDescription center &
jamfHelperUID=$(pgrep jamfHelper)
disown $jamfHelperUID
sudo jamf policy -id 209
fi
sleep 1
killall jamfHelper
ZscalerPrompt
}
ZscalerPrompt ()
{
if [ -d "/Applications/Zscaler/Zscaler.app" ]; then
"$JAMFHelperPath" -windowType utility -title "$JAMFHelperTitle" \
-icon "$JAMFHelperIcon" -iconSize 128 -heading "$JamfHelperHeading" -alignHeading left -description "Zscaler has been installed please make sure to login to the application with your Okta credentials."  \
-alignDescription left -button1 "Ok" -timeout 120 
        if [[ "$userChoice" == "0" ]]; then
        #Open the Zscaler App
        open -a /Applications/Zscaler/Zscaler.app
        else
        #Open once more
        open /Applications/Zscaler/Zscaler.app
        fi
fi
jamf recon
}
ZscalerSelection
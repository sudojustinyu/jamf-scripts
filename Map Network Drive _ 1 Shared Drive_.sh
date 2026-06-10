#!/bin/bash
process="IslandService"
if ! pgrep -f "$process"; then
        /Library/Application\ Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper \
        -windowType utility \
        -title "Open Island" \
        -heading "Reminder: Please open and login to Island Browser to proceed" \
        -description " Please click on the Open button to launch Island and sign in to be able to proceed with connecting to your Shared Drive" \
        -button1 "Open" \

        if [[ "$userChoice" == "0" ]]; then
        #Open the Zscaler App
        open -a /Applications/Island.app
        sleep 5
		jamf manage
        else
        #Open once more
        open /Applications/Island.app
        fi
sleep 7
fi
if pgrep -f "$process"; then
        currentuser=`stat -f "%Su" /dev/console`
        ShareDrive1=$4
		sleep 1
        su "$currentuser" -c "defaults write com.apple.finder ShowMountedServersOnDesktop -bool true;"
        #below this it will map a network drive for ShareDrive1
        ###############################################
        theuser=$(/usr/bin/who | awk '/console/{ print $1 }')
        /usr/bin/osascript > /dev/null << EOT

        application "Finder" 
        activate
        mount volume "$ShareDrive1"
        end 
###############################################


EOT

echo "Network Drive Mapped"
killall cfprefsd
killall -HUP Finder

exit 0
fi

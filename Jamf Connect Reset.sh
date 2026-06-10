#!/bin/sh

#Get current user
currentuser=$(scutil <<< "show State:/Users/ConsoleUser" | awk '/Name :/ && ! /loginwindow/ { print $3 }')
echo $currentuser

#Delete Jamf Connect config
sudo su - "$currentuser" -c "defaults delete com.jamf.connect.state"

#Close Jamf Connect so it can restart
pkill "Jamf Connect"

exit 0
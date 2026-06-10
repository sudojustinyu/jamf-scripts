#!/bin/sh

# wait until the Dock process has started
while [[ "$setupProcess" = "" ]]
do
	echo "Waiting for Dock"
	setupProcess=$( /usr/bin/pgrep "Dock" )
	sleep 5
done

########## variable-ing ##########



loggedInUser=$(/usr/bin/stat -f%Su "/dev/console")



########## main process ##########



# Update Jamf Pro inventory, assign to currently logged-in user.
/usr/local/bin/jamf recon -endUsername "$loggedInUser"



exit 0
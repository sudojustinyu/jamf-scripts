# wait until the Dock process has started
while [[ "$setupProcess" = "" ]]
do
	echo "Waiting for Dock"
	setupProcess=$( /usr/bin/pgrep "Dock" )
	sleep 3
done

sudo jamf policy -event dock
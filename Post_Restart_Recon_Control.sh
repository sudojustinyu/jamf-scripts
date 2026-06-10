#!/bin/bash

maxAttempts="30"

## Data for the LaunchDaemon
LAUNCHD_PLIST='<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.saks.postrestart.recon</string>
	<key>ProgramArguments</key>
	<array>
		<string>/private/var/postrestart.recon.sh</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>'

## Path to the local control plist file
CONTROL_PLIST="/Library/Preferences/com.saks.postrestart.reconcontrol.plist"

## Path to the local script that is run by the LaunchDaemon
LOCAL_SCRIPT_LOCATION="/private/var/postrestart.recon.sh"

## Data for the local script to be created
LOCAL_SCRIPT='#!/bin/bash
CONTROL_PLIST="/Library/Preferences/com.saks.postrestart.reconcontrol.plist"
function reconLoop ()
{
SERVER_TEST=$(/usr/local/bin/jamf checkJSSConnection 2>&1 > /dev/null; echo $?)
## The script will make up to '${maxAttempts}' attempts to contact the Jamf server before exiting, or will perform the recon once it establishes a connection
until [[ $x -eq '${maxAttempts}' ]]; do
	## If the jamf checkJSSConnection exited with a 0 status, perform a recon...
	if [[ "$SERVER_TEST" == 0 ]]; then
		/usr/local/bin/jamf recon
		sleep 1
		## Update the plist value to false to prevent an additional unintended run
		/usr/bin/defaults write "$CONTROL_PLIST" PerformRecon -bool FALSE
		## Make sure the plist can be written to later with a policy
		chmod 755 "$CONTROL_PLIST"
		exit 0
	else
		## If the jamf checkJSSConnection did not exit 0, wait 1 second before looping
		echo "Pausing 1 second to wait for Jamf server to be available"
		sleep 1
	fi
	((x++))
done
}
## Check if the plist file exists, and if a value can be pulled from it
if [ -e "$CONTROL_PLIST" ]; then
	VALUE=$(/usr/bin/defaults read "$CONTROL_PLIST" PerformRecon 2>/dev/null)
	## If the value is set to true, or there was no value set...
	if [[ "$VALUE" == "1" ]] || [[ -z "$VALUE" ]]; then
		## ...set an initial loop integer value, and move on to the recon loop function
		x=1
		reconLoop
	else
		## If the value is set to anything other than true or not null, exit the process without performing a recon
		echo "No post restart recon required. Exiting..."
		exit 0
	fi
else
	echo "No plist file found. Performing a recon loop just in case. The plist file will be created after completion"
	reconLoop
fi'

## Create the local script
cat << EOS > "$LOCAL_SCRIPT_LOCATION"
${LOCAL_SCRIPT}
EOS

## Ensuree the local script is executable
/bin/chmod +x "$LOCAL_SCRIPT_LOCATION"

## Create the LaunchDaemon
cat << EOD > /Library/LaunchDaemons/com.saks.postrestart.recon.plist
${LAUNCHD_PLIST}
EOD

## Set the proper owner/group and POSIX permissions on the LaunchDaemon plist
/usr/sbin/chown root:wheel /Library/LaunchDaemons/com.saks.postrestart.recon.plist
/bin/chmod 644 /Library/LaunchDaemons/com.saks.postrestart.recon.plist

echo "LaunchDaemon and script creation completed."
exit 0
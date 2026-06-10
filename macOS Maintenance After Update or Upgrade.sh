#!/bin/sh

# Location of macOS Build plist for comparison
buildPlist="/usr/local/Saks/macOSBuild.plist"

# Get the local os build version
# Using build version accounts for supplimental updates as well as dot updates and os upgrades
localOS=$( /usr/bin/sw_vers | awk '/BuildVersion/{print $2}' )

# Get the login window status for Jamf Connect
loginwindow_check=$(security authorizationdb read system.login.console | grep 'loginwindow:login' 2>&1 > /dev/null; echo $?)

# If the macOS Buld plist key does not exist, create it and write the local os into it
if [ ! -f "$buildPlist" ]; then
	echo "macOS Build plist does not exist. Creating now..."
    /usr/libexec/PlistBuddy -c 'print "macOSBuild"' $buildPlist
	defaults write $buildPlist macOSBuild $localOS
    
    # Update inventory for first time run
	echo "Running recon for first time setup..."
	/usr/local/bin/jamf recon
    
else
	echo "macOS Build plist already exists. Skipping creation..."
fi

# Get the os from the macOS build plist now that we have ensured it exists
plistOS=$( defaults read $buildPlist macOSBuild )

# If the local OS does not match the plist OS do some maintainance
if [ $localOS != $plistOS ] ; then
	echo "Performing maintenance now..."
		
	# Check if Jamf Connect Login Window is enabled 
    if [ $loginwindow_check == 0 ]; then
    	echo "OS LoginWindow, no need to reset."
	else
    	echo "Disabling Jamf Connect Login Window..."
        sudo authchanger -reset
	fi
	
    # Update inventory
	echo "Updating inventory..."
	/usr/local/bin/jamf recon
	
	# Update the local plist file
	echo "Updating plist with new OS build version..."
	defaults write $buildPlist macOSBuild $localOS

else
	echo "macOS was not updated."

fi
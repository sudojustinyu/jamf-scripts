#!/bin/bash
##############
# This is the removal script for the 10minAdminJss.sh script. 

##############

if [[ -f /var/log/hbc/userToRemove ]]; then
	U=`cat /var/log/hbc/userToRemove`
	echo "removing" $U "from admin group"
	#dscl . -delete /Groups/admin GroupMembership $U
	/usr/sbin/dseditgroup -o edit -d $U -t user admin
	echo $U "has been removed from admin group"
	rm -f /var/log/hbc/userToRemove
else
	defaults write /Library/LaunchDaemons/com.hbctech.adminremove.plist disabled -bool true
	echo "going to unload"
	launchctl unload -w /Library/LaunchDaemons/com.hbctech.adminremove.plist
	echo "Completed"
	rm -f /Library/LaunchDaemons/com.hbctech.adminremove.plist
fi

exit 0
#!/bin/bash
##############
# This script will give a user 15 minutes of Admin level access, from Jamf's self service.
##############

U=`who |grep console| awk '{print $1}'`

# Message to user they have admin rights for 15 min. 
/usr/bin/osascript <<-EOF
			    tell application "System Events"
			        activate
			        display dialog "You now have admin rights to this machine for 15 minutes" buttons {"Access Granted, proceed."} default button 1
			    end tell
			EOF

# Place launchD plist to call JSS policy to remove admin rights.
#####
echo "<?xml version="1.0" encoding="UTF-8"?> 
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> 
<plist version="1.0"> 
<dict>
	<key>Disabled</key>
	<true/>
	<key>Label</key> 
	<string>com.hbctech.adminremove</string> 
	<key>ProgramArguments</key> 
	<array> 
		<string>/usr/sbin/jamf</string>
		<string>policy</string>
		<string>-trigger</string>
		<string>adminremove</string>
	</array>
	<key>StartInterval</key>
	<integer>900</integer> 
</dict> 
</plist>" > /Library/LaunchDaemons/com.hbctech.adminremove.plist
#####

#set the permission on the file just made.
chown root:wheel /Library/LaunchDaemons/com.hbctech.adminremove.plist
chmod 644 /Library/LaunchDaemons/com.hbctech.adminremove.plist
defaults write /Library/LaunchDaemons/com.hbctech.adminremove.plist disabled -bool false

# load the removal plist timer. 
launchctl load -w /Library/LaunchDaemons/com.hbctech.adminremove.plist

# build log files in var/log/hbc
mkdir /var/log/hbc
TIME=`date "+Date:%m-%d-%Y TIME:%H:%M:%S"`
echo $TIME " by " $U >> /var/log/hbc/10minAdmin.txt

echo $U >> /var/log/hbc/userToRemove

# give current logged user admin rights
/usr/sbin/dseditgroup -o edit -a $U -t user admin
exit 0
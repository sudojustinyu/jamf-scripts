#!/bin/bash
# Grant Admin Permissions for 30 Minutes

# This script grants the currently logged in standard user admin privileges, creates a Luanch Daemon which, after 30 minutes, calls a Jamf custom trigger that runs this same script to revert the same user back to a standard account.  This is done by writing a hidden receipt indicating the user that was elevated to admin in /var/.saksTempAdmin.txt.  Each time this script is run, it will look for this receipt to make sure the appropriate user is being reverted to standard or to grant admin access if the receipt doesn't exist. Note this script must be run from Self Service, ongoing with a custom trigger of "revertAccount".

# Sets the receipt file location
receiptFile="/var/.saksTempAdmin.txt"
userToDowngrade=$(cat "$receiptFile")
# Get the current user
currentUser=$(ls -l /dev/console | /usr/bin/awk '{ print $3 }')
# Is current user an admin already?
isAdmin=$(dseditgroup -o checkmember -m $currentUser admin | awk '{print $1}')
# The message to show the user
jamfBinary=$(which jamf)
helperDescription="This account has been temporarily provided ADMIN PRIVILEGES.  After 30 MINUTES, this account will revert to STANDARD privileges."
##
##
# Look for saks Self Service branding and assign icon to Jamf Helper if found
if [ -e "/Users/$currentUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png" ]
   then
   		echo "saks branding image exists...."
   		JAMFHelperIcon="/Users/$currentUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"
	else
		echo "Using the System icon...."
		JAMFHelperIcon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/UserIcon.icns"
fi
##
##
# Setting the Jamf helper path to a variable
jamfHelperPath="/Library/Application Support/JAMF/bin/jamfHelper.app/Contents/MacOS/jamfHelper"
#
##
##
#
function userPromptGrant {
	
	# submitting recon to update Jamf record
	"$jamfBinary" recon
	
	# Prompting user with jamf helper window.
	HELPER=$("$jamfHelperPath" -windowType utility -icon "$JAMFHelperIcon" -heading "saks | Account Permissions Update" -description "${helperDescription}" -button1 "OK")
	
}

function deleteLaunchdAndReceipt() {
	echo "deleting launch control items...."
	launchctl remove /Library/LaunchDaemons/com.saks.GrantAdmin.plist
	launchctl unload -w /Library/LaunchDaemons/com.saks.GrantAdmin.plist
	rm /Library/LaunchDaemons/com.saks.GrantAdmin.plist
	rm /var/.saksTempAdmin.txt
}


function downgradeUserToStandard() {
		# This script function downgrades the user that was previously promoted Admin to Standard privileges.  It reads the receipt in /var/.saksTempAdmin.txt to make sure the user being downgraded is the same that was initially prompoted to Admin. The LaunchD from TemporaryAdminAccess_Grant.sh is removed, as is hidden receipt file.

		function userPromptRevoke {
			echo "prompting user account is now standard...."
			helperDescription="Please note that the account "${currentUser}" has been reverted back to a Standard user account.  Admin permissions have now been removed."

			# Prompting user with jamf helper window.
			HELPER=$("$jamfHelperPath" -windowType utility -icon "$JAMFHelperIcon" -heading "saks | Account Permissions Update" -description "${helperDescription}" -button1 "OK")	

			sleep 5
			"$jamfBinary" recon
			# delete files
			deleteLaunchdAndReceiptAfterDowngrade	
		}

		function deleteLaunchdAndReceiptAfterDowngrade() {
			echo "deleting launch control items...."
			launchctl remove /Library/LaunchDaemons/com.saks.GrantAdmin.plist
			launchctl unload -w /Library/LaunchDaemons/com.saks.GrantAdmin.plist
			rm /Library/LaunchDaemons/com.saks.GrantAdmin.plist
			rm /var/.saksTempAdmin.txt
			rm /Library/Scripts/revertAccount.sh
		}
		#
		##
		##
		# checking for receipt file
		if [ -e "$receiptFile" ];
		then
			echo "receipt file exists. continuing...."
		else
			echo "no receipt file found. quitting...."
			exit 1
		fi

		# Confirming the user is logged in
		if [[ "$currentUser" != "root" ]];
		then
			echo "$currentUser logged in...."
			# Checking if user is an admin
			if [[ $isAdmin == "yes" ]] && [[ $currentUser == $userToDowngrade ]];
			then
				# User is an admin and correct user to downgrade
				echo "User verified as correct user to downgrade...."
				echo "Downgrading user from admin to standard privileges...."
				dseditgroup -o edit -d "$currentUser" -t user admin
				# Launch Jamf helper window then log out user
				userPromptRevoke
			else
				echo "some issue occurred. listing info below...."
				echo "$currentUser is logged in already Standard account...."
				echo "$currentUser is an admin = "$isAdmin"...."
				echo "$userToDowngrade is marked user to be downgraded...."
			fi
			
		else
			echo "$currentUser logged in. quitting...."
		fi

		"$jamfBinary" recon

		exit 0

}
#
########################################
########################################
############# BEGIN  MAIN  #############
########################################
########################################
#
# Check for receipt file and if found, check if user is admin.  If both are true, run the downgradeUserToStandard() function.
if [[ -e "$receiptFile" ]];
then
	echo "$receiptFile exists, continuing...."
	if [[ $isAdmin == "yes" ]] && [[ $currentUser == $userToDowngrade ]];
	then
		echo "$currentUser is admin and listed in receipt. running downgrade function...."
		downgradeUserToStandard
	elif [[ $isAdmin == "no" ]] && [[ $currentUser == $userToDowngrade ]];
	then
		echo "Receipt found but $currentUser is not an admin. running cleanup function to remove launchd and other items...."
		deleteLaunchdAndReceipt
	elif [[ $isAdmin == "yes" ]] && [[ $currentUser != $userToDowngrade ]];
	then
		echo "Receipt found and $currentUser is an admin but the downgraded user should be $userToDowngrade. quitting...."
		echo "wrong user logged in...."
		exit 1
	fi
else
	echo "$receiptFile not found. running Grant Temp Admin Permissions...."
fi
#
##
##
# Confirming the user is logged in
if [[ $isAdmin == "yes" ]];
then
	# User is already an admin
	echo "the user ${currentUser} is already an admin...."
	helperDescription="The account "${currentUser}" is already an admin."
	# Launch Jamf helper window
	userPromptGrant
	else
		echo "Granting user admin privileges to account: "${currentUser}"...."
		# Setting the text in the helper window
		helperDescription="The account "${currentUser}" has been temporarily upgraded to an ADMIN.  This account will revert back to STANDARD privileges in 30 MINUTES."
		# Setting user privileges to admin
		dseditgroup -o edit -a $currentUser -t user admin
		# write the user that is being elevated to admin to the receipt file
		touch "$receiptFile"
		echo "$currentUser" > "$receiptFile"
		#####
		#####
		#####
		#####
echo '<?xml version="1.0" encoding="UTF-8"?> 
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd"> 
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.saks.GrantAdmin.plist</string>
		<key>ProgramArguments</key>
		<array>
			<string>/usr/local/bin/jamf</string>
			<string>policy</string>
			<string>-event</string>
			<string>revertAccount</string>
		</array> 
		<key>StartInterval</key>
		<integer>1800</integer>
</dict> 
</plist>' > /Library/LaunchDaemons/com.saks.GrantAdmin.plist

		chmod 644 /Library/LaunchDaemons/com.saks.GrantAdmin.plist
		chown root:wheel /Library/LaunchDaemons/com.saks.GrantAdmin.plist

		launchctl load -w /Library/LaunchDaemons/com.saks.GrantAdmin.plist
				
		# Launch Jamf helper window
		userPromptGrant
fi

"$jamfBinary" recon

exit 0
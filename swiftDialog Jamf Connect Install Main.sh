#!/bin/zsh



autoload is-at-least
dialogapp="/usr/local/bin/dialog"
dialoglog="/var/tmp/dialog.log"
org="Saks"
iconsize="200"
waittime=11
title="Jamf Connect"
apptoinstall="JamfConnect"
appversionrequired="1"
maxdeferrals="3"
policytrigger="jamfconnect1"
banner="https://media.licdn.com/dms/image/C5616AQErnUhr5y69MA/profile-displaybackgroundimage-shrink_200_800/0/1659942354357?e=2147483647&v=beta&t=pO54w-DBRXWKP7QunrLxO8PDnrPCrmygnPmYFMfJGO4"
infotext="More Information"
infolink="https://docs.google.com/presentation/d/1APyuf_ig4UgU5obvNx87UNktzJN-Uoq_bXE5oLMFrdg/edit#slide=id.g11550dab9c0_0_1223"

function JCC ()
{
if [ -d /Applications/Jamf\ Connect.app ]; then
	echo "Script is not needed Jamf Connect alreadys exists. Exiting"
    exit 0
else
	echo "Conditions met. Script will continue"
	swiftDialogcheck
fi
}

function swiftDialogcheck()
{
# Validate swiftDialog is installed
if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
	echo "Dialog not found, installing..."
	sudo jamf policy -id 360
    sleep 2
	if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
		echo "Install verification failed, could not continue..."
		exit 1
	else
		echo "Install was successful proceeding"
        JCS
	fi
else
	echo "Dialog v$(dialog --version) installed, continuing..."
    JCS
fi

}

function JCS ()
{
# work out remaining deferrals"
appdomain="${org// /_}.$(echo $apptoinstall | awk -F '/' '{print $NF}')"
deferrals=$(defaults read ${appdomain} deferrals || echo ${maxdeferrals})

if [[ $deferrals -gt 0 ]]; then
	button2text="Defer"
else
	button2text="Max Deferrals Reached"
fi
loggedInUser=$( echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
#oldicon="/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png"
icon="https://saks.jamfcloud.com/api/v1/branding-images/download/7"
deferralsremaining=$(( $maxdeferrals - $deferrals ))
# construct the dialog
message1="### Jamf Connect Installation\n\nYou are receiving this message because your laptop does NOT have Jamf Connect installed.\n\n Please be sure to install the app to keep your Okta and computer passwords in sync. \n\n \
_Remaining Deferrals: **$deferrals**_\n\n \
"
	# This is where we define the dialog window options asking the user if they want to do the thing.
    "$dialogapp" \
    --bannerimage ${banner} \
    --title "none" --ontop \
    --message ${message1} \
    --icon $icon \
    --iconsize $iconsize \
    --button1text "Install" \
    --button2text $button2text \
    --infobuttonaction ${infolink} \
    --infobuttontext ${infotext} \
    --height 420 \
    
	dialogResults=$?
	if [ "$dialogResults" = "0" ];then
		echo "Installing"
        Choice
	elif [ "$dialogResults" = "2" ]; then
    		defaults write ${appdomain} deferrals -int ${deferrals}
            if [[ $deferrals -le 0 ]]; then
            	echo "Max deferrals reached"
            	Choice
            else
        	deferrals=$(( $deferrals - 1 ))
    		deferralsremaining=$(( $maxdeferrals - $deferrals ))
			defaults write ${appdomain} deferrals -int ${deferrals}
    		echo "User chose deferral $deferralsremaining of $maxdeferrals"
            exit 0
            fi
	else
    	Choice
	fi

}
function Choice ()
{
	killall NotificationCenter
	echo "Continuing with install"
	# cleanup deferral count
	defaults delete ${appdomain} deferrals
	
	# popup wait dialog for 60 seconds to give the user something to look at
	$dialogapp --title "${title} Install" \
			  --icon $icon \
			  --height 230 \
			  --progress ${waittime} \
			  --progresstext "" \
			  --message "Please wait while ${title} is installed" \
			  --commandfile "$dialoglog" &
	
	# background for loop to display the dialog		  
	for ((i=1; i<=${waittime}; i++)); do 
		echo "progress: increment" >> $dialoglog
		sleep 1
		if [[ $i -eq ${waittime} ]]; then
			echo "progress: complete" >> $dialoglog
			sleep 1
			echo "quit:" >> $dialoglog
		fi
	done &
	# run the install policy in the background
	echo "Launching policy ${policytrigger}"
	/usr/local/bin/jamf policy -event ${policytrigger} 
    JCF
    
	

}
function JCF ()
{

sudo jamf policy -id 364

}

JCC
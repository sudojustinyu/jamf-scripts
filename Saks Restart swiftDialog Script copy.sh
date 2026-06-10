#!/bin/zsh

swiftDialog="/usr/local/bin/dialog"

# Determine current Unix epoch time
current_unix_time="$(date '+%s')"

# This reports the unix epoch time that the kernel was booted
boot_unix_time="$(sysctl -n kern.boottime | awk -F 'sec = |, usec' '{ print $2; exit }')"

# Get uptime in seconds by doing maths
uptime_seconds="$(( current_unix_time - boot_unix_time ))"


# Calculate uptime in days
uptime_minutes="$(( uptime_seconds / 60 ))"
uptime_hours="$(( uptime_minutes / 60 ))"
uptime_days="$(( uptime_hours / 24 ))"
banner="https://media.licdn.com/dms/image/C5616AQErnUhr5y69MA/profile-displaybackgroundimage-shrink_200_800/0/1659942354357?e=2147483647&v=beta&t=pO54w-DBRXWKP7QunrLxO8PDnrPCrmygnPmYFMfJGO4"
selecttitle="Select an Option"
icon=/Users/Shared/sakslogo.jpg
#overlayicon="SF=laptopcomputer.and.arrow.down,weight=semibold,colour1=#ff5349,colour2=#ffae49 bgcolor=none"
message="**Restart Required** \n\nYour computer's last restart was **${uptime_days}** days ago.\n\nIn order to keep your system healthy and secure it needs to be restarted. \n\nPlease save your work and restart as soon as possible." 
timermessage="**Restart Required** \n\nYour computer's last restart was **${uptime_days}** days ago.\n\nIn order to keep your system healthy and secure it needs to be restarted. \n\nPlease make sure to **save your work** before the timer ends." 
selectvalues="Defer 1 Minute,Defer 5 Minutes,Defer 10 Minutes,Defer 15 Minutes,Restart Now, Not Today"
button1text="Select"
selectdefault="Restart Now"
title="none"
button2text="Not Now"
#Written by Trevor Sysock (@BigMacAdmin on Slack)
#Example script: How to capture button output and make actions based on the results
function RestartEligibility()
{
if [[ $uptime_days -ge 0 ]]
then
	echo "Proceeding with Script"
	if [ -f /Library/LaunchDaemons/saks.postrestart.reconAtReboot.plist ];then
    	echo "LaunchDaemon that runs recon on startup exists will proceed with the script"
        swiftDialogCheck
    else
    	echo "LaunchDaemon that runs recon on startup DOES NOT exists will proceed with the installation"
        sudo jamf policy -id 314
        if [ -f /Library/LaunchDaemons/saks.postrestart.reconAtReboot.plist ];then
    		echo "LaunchDaemon that runs recon on startup exists will proceed with the script"
            swiftDialogCheck
        else
			echo "LaunchDaemon failed to install will exit out"
        	exit 0
        fi
    fi

else
	echo "User has restarted within 30 days will exit out"
	exit 0
fi
}

function swiftDialogCheck(){
# Validate swiftDialog is installed
if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
	sudo jamf policy -id 360
    sleep 2
	if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
		echo "Install verification failed, could not continue..."
		exit 0
	else
		echo "Install was successful"
        RestartPrompt
	fi
else
	echo "Dialog v$(dialog --version) installed, continuing..."
    RestartPrompt
fi
}

function RestartPrompt()
{

dialogCMD="$swiftDialog \
--title \"$title\" --ontop \
--bannerimage \"${banner}\" \
--message \"$message\" \
--icon \"$icon\" \
--overlayicon \"$overlayicon\" \
--button1text \"$button1text\" \
--selecttitle \"$selecttitle\" \
--selectvalues \"$selectvalues\" \
--selectdefault \"$selectdefault\" \
--messagefont \"size=18\" \
--height 400
--quitkey K
--timer 15
dialogResults=$?"


if [ "$dialogResults" = "4" ];then
	echo "Timed out"
    exit 4
fi


# Evaluate user selection
userInput=$( eval "$dialogCMD" )

# Set Variable to make work array
option=$( echo "$userInput" | grep "SelectedIndex" | awk -F " : " '{print $NF}' )

case ${option} in
	0)  echo "User Selected 1 Minute"
		SelectedIndex1="0"
	;;
	
	1)  echo "User Selected 5 Minutes"
		SelectedIndex1="1"
	;;

	2)  echo "User Selected 10 Minutes"
		SelectedIndex1="2"
	;;
	
	3)  echo "User Selected 15 Minutes"
		SelectedIndex1="3"
	;;

	4) echo "User Selected Restart Now"
		SelectedIndex1="4"
	;;
    
    5) echo "User Selected Not Today"
		SelectedIndex1="5"
	;;
esac

if [ "$SelectedIndex1" = "0" ]; then
	Defer_1minute
elif [ "$SelectedIndex1" = "1" ]; then
	Defer_5minutes
elif [ "$SelectedIndex1" = "2" ]; then
	Defer_10minutes
elif [ "$SelectedIndex1" = "3" ]; then
	Defer_15minutes
elif [ "$SelectedIndex1" = "4" ]; then
	osascript -e 'tell app "loginwindow" to «event aevtrrst»'
elif [ "$SelectedIndex1" = "5" ]; then
	echo "Will Exit Out"
    exit 0
fi

}

function Defer_1minute() 
{
	/usr/local/bin/dialog \
	--bannerimage ${banner} \
    --title "none" \
	--message ${timermessage} \
	--icon $icon \
    --overlayicon $overlayicon \
	--button1text "Restart Now Instead" \
    --messagefont size=18 \
	--timer 60
		#--quitkey k \
	dialogResults=$?
	if [ "$dialogResults" = "0" ];then
		echo "User chose 'Restart Now Instead' will present the restart button"
		osascript -e 'tell app "loginwindow" to «event aevtrrst»'
	elif [ "$dialogResults" = "4" ]; then
		echo "Timer expired restarting now"
		#osascript -e 'tell app "loginwindow" to «event aevtrrst»'
		osascript -e 'tell app "loginwindow" to «event aevtrrst»'
    else
    	echo "The swiftDialog prompt was closed present the user the option to restart"
		osascript -e 'tell app "loginwindow" to «event aevtrrst»'
	fi
}

function Defer_5minutes() 
{
	/usr/local/bin/dialog \
	--bannerimage ${banner} \
    --title "none" \
	--message ${timermessage} \
	--icon $icon \
    --overlayicon $overlayicon \
	--button1text "Restart Now Instead" \
    --messagefont size=18 \
	--timer 300
		#--quitkey k \
	dialogResults=$?
	if [ "$dialogResults" = "0" ];then
		echo "User chose 'Restart Now Instead' will present the restart button"
		osascript -e 'tell app "loginwindow" to «event aevtrrst»'
	elif [ "$dialogResults" = "4" ]; then
		echo "Timer expired restarting now"
		#osascript -e 'tell app "loginwindow" to «event aevtrrst»'
		osascript -e 'tell app "loginwindow" to «event aevtrrst»'
    else
    	echo "The swiftDialog prompt was closed present the user the option to restart"
		osascript -e 'tell app "loginwindow" to «event aevtrrst»'
	fi
}

function Defer_10minutes() 
{
	/usr/local/bin/dialog \
	--bannerimage ${banner} --moveable \
    --title "none" \
	--message ${timermessage} \
	--icon $icon \
    --overlayicon $overlayicon \
	--button1text "Restart Now Instead" \
    --messagefont size=18 \
	--timer 600
		#--quitkey k \
	dialogResults=$?
	if [ "$dialogResults" = "0" ];then
		echo "User chose 'Restart Now Instead' will present the restart button"
		osascript -e 'tell app "loginwindow" to «event aevtrrst»'
	elif [ "$dialogResults" = "4" ]; then
		echo "Timer expired restarting now"
		#osascript -e 'tell app "loginwindow" to «event aevtrrst»'
		osascript -e 'tell app "loginwindow" to «event aevtrrst»'
    else
    	echo "The swiftDialog prompt was closed present the user the option to restart"
		osascript -e 'tell app "loginwindow" to «event aevtrrst»'
	fi
}

function Defer_15minutes() 
{
	/usr/local/bin/dialog \
	--bannerimage ${banner} --moveable \
    --title "none" \
	--message ${timermessage} \
	--icon $icon \
    --overlayicon $overlayicon \
	--button1text "Restart Now Instead" \
    --messagefont size=18 \
	--timer 900
		#--quitkey k \
	dialogResults=$?
	if [ "$dialogResults" = "0" ];then
		echo "User chose 'Restart Now Instead' will present the restart button"
		osascript -e 'tell app "loginwindow" to «event aevtrrst»'
	elif [ "$dialogResults" = "4" ]; then
		echo "Timer expired restarting now"
		#osascript -e 'tell app "loginwindow" to «event aevtrrst»'
		osascript -e 'tell app "loginwindow" to «event aevtrrst»'
    else
    	echo "The swiftDialog prompt was closed present the user the option to restart"
		osascript -e 'tell app "loginwindow" to «event aevtrrst»'
	fi
}
RestartEligibility


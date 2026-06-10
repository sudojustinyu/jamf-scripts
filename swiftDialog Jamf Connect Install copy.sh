#!/bin/zsh
#set -x 

# deferralsExample.sh
# v.1.0

# Written by Trevor Sysock @BigMacAdmin

# Please see the software license in the associated GitHub repo: 
# https://github.com/SecondSonConsulting/swiftDialogExamples

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# Overview:
# This script is meant to be an example framework for how to prompt users
# to complete an action and offer deferrals.

# The concept here is that you can call a script repeatedly on whatever
# schedule suits your needs. The script will exit clean and quiet if a 
# deferral is active, or if the "check_the_things" function decides no action
# is needed.

######################
#   How to Configure #
######################

# All time/date calculations are given in seconds

# Admins will want to at least configure everything within the "User Configuration Variables"
# and the "User Configuration Functions" section of the script.

#########
# Tools #
#########
loggedInUser=$( echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
# Path to SwiftDialog
dialogPath="/usr/local/bin/dialog"

# Path to SwiftDialog Log
dialoglog="/var/tmp/dialog.log"
policytrigger=jamfconnect1
waittime=10


# Path to PlistBuddy. We'll use this to write to our config file
pBuddy="/usr/libexec/PlistBuddy"

################################
# User Configuration Variables #
################################

# How long until a deferral expires? Value in seconds. Set this low for testing.
deferralDuration="2"

# How many deferrals until you no longer offer them? In this example, the DeferralCount value is reset
# when the "do_the_things" action completes successfully.
deferralMaximum="600"

# Deadline Date. This is a unix epoch time value. 
# To get this value converted from a human readable date you can use a "unix epoch time" 
# calculator like this one: https://www.epochconverter.com/
# If the script runs after this deadline date, no deferrals will be offered.
# Leave empty if you don't want to use this feature
deadlineDate=""

# Full file path to your configuration profile.
# For this example, we'll just stay in the current working directory.
# 
# You will want to consider "Is this a root daemon or a user agent?" as well as
# whether you want separate deferral files for multiple users or one file
# for the system.
deferralPlist="com.saks1.deferral.plist"



infotext="${4:-"More Information"}"
infolink="${5:-"https://docs.google.com/presentation/d/1APyuf_ig4UgU5obvNx87UNktzJN-Uoq_bXE5oLMFrdg/edit#slide=id.g11550dab9c0_0_1223"}"
infolink2="${6:-"https://docs.google.com/presentation/d/1APyuf_ig4UgU5obvNx87UNktzJN-Uoq_bXE5oLMFrdg/edit#slide=id.g1267455a18b_0_23"}"
banner="${7:-"https://media.licdn.com/dms/image/C5616AQErnUhr5y69MA/profile-displaybackgroundimage-shrink_200_800/0/1659942354357?e=2147483647&v=beta&t=pO54w-DBRXWKP7QunrLxO8PDnrPCrmygnPmYFMfJGO4"}"

#################################
# User Configuration Functions  #
#################################

function JamfConnect_Check()
{
    # Use this if you need to add a check to see if the purpose of this script needs to be actioned on.
    # For example, if you wanted this script to take action when the "uptime" of a device has exceeded a 
    # certain value, here is where you would put that check.
    # If "check the things" exits true, then the script continues on. If it exits false (non-zero exit/return code) then
    # the thing doesn't need to happen and the script exits.
    # You can omit this function entirely if you want the script to take action always.

    # For our example, we'll use "If true" which always returns true (or exit code zero) Change to "if false" for 
    # testing the opposite.
    if [ -d /Applications/Jamf\ Connect.app ]; then
        cleanup_and_exit 0 "Script is not needed Jamf Connect alreadys exists. Exiting"
    else
        log_message "Conditions met. Script will continue"
    fi
}

function JamfConnect_Installation()
{
	killall NotificationCenter
    # This is where you put the actual action you want the script to take. This is executed when the user consents by 
    # clicking "OK" on the Dialog window
	echo "Continuing with install"
	# cleanup deferral count
	message2="### Please wait while Jamf Connect is installed \n\n \
	"
	# popup wait dialog for 60 seconds to give the user something to look at
	$dialogPath --title "Jamf Connect Install" \
              --icon "/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png" \
              --height 230 \
			  --progress ${waittime} \
			  --progresstext "" \
			  --message ${message2} \
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
    
    
    # Since we did the things, we'll set the deferral count back to 0.
    # You may want to move this elsewhere in the script, or do things differently. For our example, it makes sense
    # to put this here.
    $pBuddy -c "Set DeferralCount 0" $deferralPlist
  
}

function JamfConnect_Prompt_With_Deferral()
{
deferrals=$(( $deferralMaximum - $deferralCount ))
message1="### Jamf Connect Installation\n\nYou are receiving this message because your laptop does NOT have Jamf Connect installed.\n\n Please be sure to install the app to keep your Okta and computer passwords in sync. \n\n \
_Remaining Deferrals: **${deferrals}**_\n\n \
"
	# This is where we define the dialog window options asking the user if they want to do the thing.
    "$dialogPath" \
    --bannerimage ${banner} \
    --title "none" --ontop \
    --message ${message1} \
    --icon "/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png" \
    --button1text "Install" \
    --button2text "Not Now" \
    --infobuttontext ${infotext} \
	--infobuttonaction ${infolink} \
    --height 420 \

}

function JamfConnect_Prompt_No_Deferral()
{
deferrals=$(( $deferralMaximum - $deferralCount ))
message1="### Jamf Connect Installation\n\nYou are receiving this message because your laptop does NOT have Jamf Connect installed.\n\n Please be sure to install the app to keep your Okta and computer passwords in sync. \n\n \
_Remaining Deferrals: **$deferrals**_\n\n \
"
    # This is where we define the dialog window options when we're no longer offering deferrals. "Aggressive mode" 
    # so to speak.
    "$dialogPath" \
    --bannerimage ${banner} \
    --title "none" --ontop \
    --message ${message1} \
    --icon "/Users/$loggedInUser/Library/Application Support/com.jamfsoftware.selfservice.mac/Documents/Images/brandingimage.png" \
    --button1text "Install" \
    --button2text "Max Deferrals Reached" \
    --infobuttontext ${infotext} \
	--infobuttonaction ${infolink} \
    --height 420 \
}

##################
# Core Functions #
##################

# Send a message to the log. For the example it just echos to standard out
function log_message()
{
    echo "$(date): $@"
}

# This function exits the script. Takes two arguments. Argument 1 is the exit code 
# and argument 2 is an optional log message
# Example: cleanup_and_exit 0 "We are done, no problems found."
function cleanup_and_exit()
{
    # If you have temp folders/files that you want to delete as this script exits, this is the place to add that
    log_message "${2}"
    exit "${1}"
}

function verify_config_file()
{
    # Check if we can write to the configuration file by writing something then deleting it.
    if $pBuddy -c "Add Verification string Success" "$deferralPlist"  > /dev/null 2>&1; then
        $pBuddy -c "Delete Verification string Success" "$deferralPlist" > /dev/null 2>&1
    else
        # This should only happen if there's a permissions problem or if the deferralPlist value wasn't defined
        cleanup_and_exit 1 "ERROR: Cannot write to the deferral file: $deferralPlist"
    fi

    # See below for what this is doing
    verify_deferral_value "ActiveDeferral"
    verify_deferral_value "DeferralCount"

}

function verify_deferral_value()
{
    # Takes an argument to determine if the value exists in the deferral plist file.
    # If the value doesn't exist, it writes a 0 to that value as an integer
    # We always want some value in there so that PlistBuddy doesn't throw errors 
    # when trying to read data later
    if ! $pBuddy -c "Print :$1" "$deferralPlist"  > /dev/null 2>&1; then
        $pBuddy -c "Add :$1 integer 0" "$deferralPlist"  > /dev/null 2>&1
    fi

}

function check_for_active_deferral()
{
    # This function checks if there is an active deferral present. If there is, then it exits quietly.

    # Get the current deferral value. This will be 0 if there is no active deferral
    currentDeferral=$($pBuddy -c "Print :ActiveDeferral" "$deferralPlist")

    # If unixEpochTime is less than the current deferral time, it means there is an active deferral and we exit
    if [ "$unixEpochTime" -lt "$currentDeferral" ]; then
        cleanup_and_exit 0 "Active deferral found. Exiting"
    else
        log_message "No active deferral."
        # We'll delete the "human readable" deferral date value, if it exists.
        $pBuddy -c "Delete :HumanReadableDeferralDate" "$deferralPlist"  > /dev/null 2>&1
    fi
}


function execute_deferral()
{
    # This is where we define what happens when the user chooses to defer

    # Setting deferral variables
    # Set the date the deferral will expire. If the script runs again before this date, it exits quietly without
    # bothering the user.
    deferralDateSeconds=$((unixEpochTime + deferralDuration ))
    # This is a human readable date format of the deferral date. This serves no function except to make it easy
    # to tell when the deferral will expire.
    deferralDateReadable=$(date -j -f %s $deferralDateSeconds)
    # Increase the number of deferrals by 1. This gets checked against the maximum allowed deferrals next time
    # the script runs.
    deferralCount=$(( deferralCount + 1 ))

    # Writing deferral values to the plist
    $pBuddy -c "Set ActiveDeferral $deferralDateSeconds" $deferralPlist
    $pBuddy -c "Set DeferralCount $deferralCount" $deferralPlist
    $pBuddy -c "Add :HumanReadableDeferralDate string $deferralDateReadable" "$deferralPlist"  > /dev/null 2>&1

    # Deferral has been processed. Exit cleanly.
    cleanup_and_exit 0 "User chose deferral $deferralCount of $deferralMaximum. Deferral date is $deferralDateReadable"
}

function Final_Installation_Notification()
{
 	
	sudo jamf policy -id 364
             
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
	fi
else
	echo "Dialog v$(dialog --version) installed, continuing..."
fi

}


######################
# Script Starts Here #
######################

swiftDialogcheck

verify_config_file

# Get the current date in seconds (unix epoc time)
unixEpochTime=$(date +%s)

check_for_active_deferral

JamfConnect_Check

# Get the current deferral count
deferralCount=$($pBuddy -c "Print :DeferralCount" $deferralPlist)


# This next block does the logic to determine if we're going to allow deferrals or not


# Check if the number of deferrals used is greater than the maximum allowed
if [ "$deferralCount" -ge "$deferralMaximum" ]; then
    allowDeferral="false"
else
    # Deadline isn't past and the deferral count hasn't been exceeded, so we'll allow deferrals.
    allowDeferral="true"
fi

# For the sake of this example the logic below is simplified in the following ways:
# - It assumes that exiting 0 is consent to do the thing
# - It assumes exiting Dialog with anything other than 0 is a deferral (so CMD+Q, or if they `killall Dialog` 
#       it will process a deferral)
# - If we're not offering a deferral, then "do_the_things" gets executed regardless of the dialog exit code
# If you'd like to do things differently, you can capture the exit code of the "dialog_prompt_with_deferral" function
# and do an if/elif/else or case statement to take action based on that exit code.

# If we're allowing deferrals, then
if [ "$allowDeferral" = "true" ]; then
    # Prompt the user to ask for consent. If it exits 0, they clicked OK and we'll do the things
    if JamfConnect_Prompt_With_Deferral; then
        # Here is where the actual things we want to do get executed
        JamfConnect_Installation
        #Final Notification
        Final_Installation_Notification
		
        # Capture the exit code of our things, so we can exit the script with the same exit code
        JamfConnectExitCode=$?
        cleanup_and_exit $JamfConnectExitCode "Jamf Connect was successfully installed. Exit code: $JamfConnectExitCode"
    else
        execute_deferral
    fi
else
    # We are NOT allowing deferrals, so we'll continue with or without user consent
    JamfConnect_Prompt_No_Deferral
    JamfConnect_Installation
    #Final Notification
    Final_Installation_Notification
    
    # Capture the exit code of our things, so we can exit the script with the same exit code
    JamfConnectExitCode=$?
    cleanup_and_exit $JamfConnectExitCode "Jamf Connect was successfully installed. Exit code: $JamfConnectExitCode"
fi
#!/bin/bash

####################################################################################################
#
# Setup Your Mac via swiftDialog
# https://snelson.us/sym
#
####################################################################################################
#
# HISTORY
#
#   Version 1.9.0, 01-Apr-2023, Dan K. Snelson (@dan-snelson)
#   - Previously installed apps with a `filepath` validation now display "Previously Installed" (instead of a generic "Installed"; Issue No. 13; thanks for the idea, @Manikandan!)
#   - Allow "first name" to correctly handle names in "Lastname, Firstname" format (Pull Request No. 11; thanks, @meschwartz!)
#   - Corrected `PATH` (thanks, @Theile!)
#   - `Configuration` no longer displays in SYM's `infobox` when `welcomeDialog` is set to `false` or `video` (Issue No. 12; thanks, @Manikandan!)
#   - Updated icon hashes
#   - New `toggleJamfLaunchDaemon` function (Pull Request No. 16; thanks, @robjschroeder!)
#   - Formatted policyJSON with [Erik Lynd's JSON Tools](https://marketplace.visualstudio.com/items?itemName=eriklynd.json-tools)
#   - Corrected an issue where inventory would be submitted twice (thanks, @Manikandan!)
#
####################################################################################################



####################################################################################################
#
# Global Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Script Version and Jamf Pro Script Parameters
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

scriptVersion="1.9.0"
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
scriptLog="${4:-"/var/log/org.thebay.log"}"                        # Parameter 4: Script Log Location [ /var/log/org.churchofjesuschrist.log ] (i.e., Your organization's default location for client-side logs)
debugMode="${5:-"false"}"                                                     # Parameter 5: Debug Mode [ verbose (default) | true | false ]
welcomeDialog="${6:-"false"}"                                               # Parameter 6: Welcome dialog [ userInput (default) | video | false ]
completionActionOption="${7:-"sleep 5"}"                               # Parameter 7: Completion Action [ wait | sleep (with seconds) | Shut Down | Shut Down Attended | Shut Down Confirm | Restart | Restart Attended (default) | Restart Confirm | Log Out | Log Out Attended | Log Out Confirm ]
requiredMinimumBuild="${8:-"disabled"}"                                         # Parameter 8: Required Minimum Build [ disabled (default) | 22E ] (i.e., Your organization's required minimum build of macOS to allow users to proceed; use "22E" for macOS 13.3)
outdatedOsAction="${9:-"/System/Library/CoreServices/Software Update.app"}"     # Parameter 9: Outdated OS Action [ /System/Library/CoreServices/Software Update.app (default) | jamfselfservice://content?entity=policy&id=117&action=view ] (i.e., Jamf Pro Self Service policy ID for operating system ugprades)



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Operating System, currently logged-in user and default Exit Code
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

osVersion=$( sw_vers -productVersion )
osBuild=$( sw_vers -buildVersion )
osMajorVersion=$( echo "${osVersion}" | awk -F '.' '{print $1}' )
reconOptions=""
exitCode="0"



####################################################################################################
#
# Pre-flight Checks
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Logging
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ ! -f "${scriptLog}" ]]; then
    touch "${scriptLog}"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Client-side Script Logging Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function updateScriptLog() {
    echo -e "$( date +%Y-%m-%d\ %H:%M:%S ) - ${1}" | tee -a "${scriptLog}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Current Logged-in User Function
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function currentLoggedInUser() {
    loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
    updateScriptLog "PRE-FLIGHT CHECK: Current Logged-in User: ${loggedInUser}"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Logging Preamble
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "\n\n###\n# Setup Your Mac (${scriptVersion})\n# https://snelson.us/sym\n###\n"
updateScriptLog "PRE-FLIGHT CHECK: Initiating …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm script is running as root
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $(id -u) -ne 0 ]]; then
    updateScriptLog "PRE-FLIGHT CHECK: This script must be run as root; exiting."
    exit 1
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Setup Assistant has completed
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

while pgrep -q -x "Setup Assistant"; do
    updateScriptLog "PRE-FLIGHT CHECK: Setup Assistant is still running; pausing for 2 seconds"
    sleep 2
done

updateScriptLog "PRE-FLIGHT CHECK: Setup Assistant is no longer running; proceeding …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Confirm Dock is running / user is at Desktop
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

until pgrep -q -x "Finder" && pgrep -q -x "Dock"; do
    updateScriptLog "PRE-FLIGHT CHECK: Finder & Dock are NOT running; pausing for 1 second"
    sleep 1
done

updateScriptLog "PRE-FLIGHT CHECK: Finder & Dock are running; proceeding …"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Operating System Version and Build
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${requiredMinimumBuild}" == "disabled" ]]; then

    updateScriptLog "PRE-FLIGHT CHECK: 'requiredMinimumBuild' has been set to ${requiredMinimumBuild}; skipping OS validation."
    updateScriptLog "PRE-FLIGHT CHECK: macOS ${osVersion} (${osBuild}) installed"

else

    # Since swiftDialog requires at least macOS 11 Big Sur, first confirm the major OS version
    # shellcheck disable=SC2086 # purposely use single quotes with osascript
    if [[ "${osMajorVersion}" -ge 11 ]] ; then

        updateScriptLog "PRE-FLIGHT CHECK: macOS ${osMajorVersion} installed; checking build version ..."

        # Confirm the Mac is running `requiredMinimumBuild` (or later)
        if [[ "${osBuild}" > "${requiredMinimumBuild}" ]]; then

            updateScriptLog "PRE-FLIGHT CHECK: macOS ${osVersion} (${osBuild}) installed; proceeding ..."

        # When the current `osBuild` is older than `requiredMinimumBuild`; exit with error
        else
            updateScriptLog "PRE-FLIGHT CHECK: The installed operating system, macOS ${osVersion} (${osBuild}), needs to be updated to Build ${requiredMinimumBuild}; exiting with error."
            osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\rExpected macOS Build '${requiredMinimumBuild}' (or newer), but found macOS '${osVersion}' ('${osBuild}').\r\r" with title "Setup Your Mac: Detected Outdated Operating System" buttons {"Open Software Update"} with icon caution'
            updateScriptLog "PRE-FLIGHT CHECK: Executing /usr/bin/open '${outdatedOsAction}' …"
            su - "${loggedInUser}" -c "/usr/bin/open \"${outdatedOsAction}\""
            exit 1

        fi

    # The Mac is running an operating system older than macOS 11 Big Sur; exit with error
    else

        updateScriptLog "PRE-FLIGHT CHECK: swiftDialog requires at least macOS 11 Big Sur and this Mac is running ${osVersion} (${osBuild}), exiting with error."
        osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\rExpected macOS Build '${requiredMinimumBuild}' (or newer), but found macOS '${osVersion}' ('${osBuild}').\r\r" with title "Setup Your Mac: Detected Outdated Operating System" buttons {"Open Software Update"} with icon caution'
        updateScriptLog "PRE-FLIGHT CHECK: Executing /usr/bin/open '${outdatedOsAction}' …"
        su - "${loggedInUser}" -c "/usr/bin/open \"${outdatedOsAction}\""
        exit 1

    fi

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Ensure computer does not go to sleep during SYM (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "PRE-FLIGHT CHECK: Caffeinating this script (PID: $$)"
caffeinate -dimsu -w $$ &



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate Logged-in System Accounts
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "PRE-FLIGHT CHECK: Check for Logged-in System Accounts …"
currentLoggedInUser

counter="1"

until { [[ "${loggedInUser}" != "_mbsetupuser" ]] || [[ "${counter}" -gt "180" ]]; } && { [[ "${loggedInUser}" != "loginwindow" ]] || [[ "${counter}" -gt "30" ]]; } ; do

    updateScriptLog "PRE-FLIGHT CHECK: Logged-in User Counter: ${counter}"
    currentLoggedInUser
    sleep 2
    ((counter++))

done

loggedInUserFullname=$( id -F "${loggedInUser}" )
loggedInUserFirstname=$( echo "$loggedInUserFullname" | sed -E 's/^.*, // ; s/([^ ]*).*/\1/' )
loggedInUserID=$( id -u "${loggedInUser}" )
updateScriptLog "PRE-FLIGHT CHECK: Current Logged-in User First Name: ${loggedInUserFirstname}"
updateScriptLog "PRE-FLIGHT CHECK: Current Logged-in User ID: ${loggedInUserID}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Toggle `jamf` binary check-in (thanks, @robjschroeder!)
# shellcheck disable=SC2143
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function toggleJamfLaunchDaemon() {
    
jamflaunchDaemon="/Library/LaunchDaemons/com.jamfsoftware.task.1.plist"
if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
    if [[ $(/bin/launchctl list | grep com.jamfsoftware.task.E) ]]; then
        updateScriptLog "PRE-FLIGHT CHECK: DEBUG MODE: Normally, 'jamf' binary check-in would be temporarily disabled"
    else
        updateScriptLog "QUIT SCRIPT: DEBUG MODE: Normally, 'jamf' binary check-in would be re-enabled"
    fi
else
    while [[ ! -f "${jamflaunchDaemon}" ]] ; do
        sleep 0.1
    done
    if [[ $(/bin/launchctl list | grep com.jamfsoftware.task.E) ]]; then
        updateScriptLog "PRE-FLIGHT CHECK: Temporarily disable 'jamf' binary check-in"
        /bin/launchctl bootout system "${jamflaunchDaemon}"
    else
        updateScriptLog "QUIT SCRIPT: Re-enabling 'jamf' binary check-in"
        updateScriptLog "QUIT SCRIPT: 'jamf' binary check-in daemon not loaded, attempting to bootstrap and start"
        result="0"
        until [ $result -eq 3 ]; do
            /bin/launchctl bootstrap system "${jamflaunchDaemon}" && /bin/launchctl start "${jamflaunchDaemon}"
            result="$?"
            if [ $result = 3 ]; then
                updateScriptLog "QUIT SCRIPT: Staring 'jamf' binary check-in daemon"
            else
                updateScriptLog "QUIT SCRIPT: Failed to start 'jamf' binary check-in daemon"
            fi
        done
    fi
fi
}

toggleJamfLaunchDaemon



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Validate / install swiftDialog (Thanks big bunches, @acodega!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogCheck() {

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "PRE-FLIGHT CHECK: # # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    # Get the URL of the latest PKG From the Dialog GitHub repo
    dialogURL=$(curl -L --silent --fail "https://api.github.com/repos/bartreardon/swiftDialog/releases/latest" | awk -F '"' "/browser_download_url/ && /pkg\"/ { print \$4; exit }")

    # Expected Team ID of the downloaded PKG
    expectedDialogTeamID="PWA5E9TQ59"

    # Check for Dialog and install if not found
    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then

        updateScriptLog "PRE-FLIGHT CHECK: Dialog not found. Installing..."

        # Create temporary working directory
        workDirectory=$( /usr/bin/basename "$0" )
        tempDirectory=$( /usr/bin/mktemp -d "/private/tmp/$workDirectory.XXXXXX" )

        # Download the installer package
        /usr/bin/curl --location --silent "$dialogURL" -o "$tempDirectory/Dialog.pkg"

        # Verify the download
        teamID=$(/usr/sbin/spctl -a -vv -t install "$tempDirectory/Dialog.pkg" 2>&1 | awk '/origin=/ {print $NF }' | tr -d '()')

        # Install the package if Team ID validates
        if [[ "$expectedDialogTeamID" == "$teamID" ]]; then

            /usr/sbin/installer -pkg "$tempDirectory/Dialog.pkg" -target /
            sleep 2
            dialogVersion=$( /usr/local/bin/dialog --version )
            updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version ${dialogVersion} installed; proceeding..."

        else

            # Display a so-called "simple" dialog if Team ID fails to validate
            osascript -e 'display dialog "Please advise your Support Representative of the following error:\r\r• Dialog Team ID verification failed\r\r" with title "Setup Your Mac: Error" buttons {"Close"} with icon caution'
            completionActionOption="Quit"
            exitCode="1"
            quitScript

        fi

        # Remove the temporary working directory when done
        /bin/rm -Rf "$tempDirectory"

    else

        updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version $(/usr/local/bin/dialog --version) found; proceeding..."

    fi

}

if [[ ! -e "/Library/Application Support/Dialog/Dialog.app" ]]; then
    dialogCheck
else
    updateScriptLog "PRE-FLIGHT CHECK: swiftDialog version $(/usr/local/bin/dialog --version) found; proceeding..."
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Pre-flight Check: Complete
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

updateScriptLog "PRE-FLIGHT CHECK: Complete"



####################################################################################################
#
# Dialog Variables
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# infobox-related variables
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

macOSproductVersion="$( sw_vers -productVersion )"
macOSbuildVersion="$( sw_vers -buildVersion )"
serialNumber=$( system_profiler SPHardwareDataType | grep Serial |  awk '{print $NF}' )
timestamp="$( date '+%Y-%m-%d-%H%M%S' )"
dialogVersion=$( /usr/local/bin/dialog --version )
model=$(system_profiler SPHardwareDataType | grep "Model Name:" | sed 's/Model Name://g' | sed -e 's/^[ \t]*//')



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Reflect Debug Mode in `infotext` (i.e., bottom, left-hand corner of each dialog)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case ${debugMode} in
    "true"      ) scriptVersion="DEBUG MODE | Dialog: v${dialogVersion} • Setup Your Mac: v${scriptVersion}" ;;
    "verbose"   ) scriptVersion="VERBOSE DEBUG MODE | Dialog: v${dialogVersion} • Setup Your Mac: v${scriptVersion}" ;;
esac



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set Dialog path, Command Files, JAMF binary, log files and currently logged-in user
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogApp="/Library/Application\ Support/Dialog/Dialog.app/Contents/MacOS/Dialog"
dialogBinary="/usr/local/bin/dialog"
welcomeCommandFile=$( mktemp /var/tmp/dialogWelcome.XXX )
setupYourMacCommandFile=$( mktemp /var/tmp/dialogSetupYourMac.XXX )
failureCommandFile=$( mktemp /var/tmp/dialogFailure.XXX )
jamfBinary="/usr/local/bin/jamf"



####################################################################################################
#
# Welcome dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Welcome" dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

welcomeTitle="Happy $( date +'%A' ), ${loggedInUserFirstname} and welcome to your new Mac!"
welcomeMessage="Please enter your Position, Username, & Location, then click **Continue** to start applying settings to your new Mac.  \n\nOnce completed, the **Wait** button will be enabled, and you'll be able to review the results before proceeding to use your Mac. \n\nIf you need assistance, please contact the Help Desk via email at: techservices@saks.com  \n\n---  \n\n#### Configurations  \n- **Required:** Minimum organization apps "
welcomeBannerImage="https://live.staticflickr.com/65535/52843232549_f2caea6cbf_h.jpg"
#welcomeBannerImage="/Users/Shared/thebaybanner_smallertext.png"
#welcomeBannerImage="https://img.freepik.com/free-photo/yellow-watercolor-paper_95678-446.jpg"
#welcomeBannerText="Happy $( date +'%A' ), ${loggedInUserFirstname} and welcome to your new Mac!"
#"bannertext" : "'"${welcomeBannerText}"'",
welcomeCaption="Please review the above video, then click Continue."
welcomeVideoID="vimeoid=812753953"

# Welcome icon set to either light or dark, based on user's Apperance setting (thanks, @mm2270!)
appleInterfaceStyle=$( /usr/bin/defaults read /Users/"${loggedInUser}"/Library/Preferences/.GlobalPreferences.plist AppleInterfaceStyle 2>&1 )
if [[ "${appleInterfaceStyle}" == "Dark" ]]; then
    #welcomeIcon="https://cdn-icons-png.flaticon.com/512/740/740878.png"
    welcomeIcon="https://is1-ssl.mzstatic.com/image/thumb/Purple113/v4/df/9b/84/df9b84e6-e209-23d1-4423-1102bfc5473c/AppIcon-0-0-1x_U007emarketing-0-0-0-7-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/460x0w.webp"
else
    welcomeIcon="https://is1-ssl.mzstatic.com/image/thumb/Purple113/v4/df/9b/84/df9b84e6-e209-23d1-4423-1102bfc5473c/AppIcon-0-0-1x_U007emarketing-0-0-0-7-0-0-sRGB-0-0-0-GLES2_U002c0-512MB-85-220-0-0.png/460x0w.webp"
    #welcomeIcon="https://cdn-icons-png.flaticon.com/512/979/979585.png"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Welcome" Video Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

welcomeVideo="--title \"$welcomeTitle\" \
--videocaption \"$welcomeCaption\" \
--video \"$welcomeVideoID\" \
--infotext \"$scriptVersion\" \
--button1text \"Continue …\" \
--autoplay \
--moveable \
--ontop \
--width '800' \
--height '600' \
--commandfile \"$welcomeCommandFile\" "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Welcome" JSON for Capturing User Input (thanks, @bartreardon!) 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

welcomeJSON='
{
    "bannerimage" : "'"${welcomeBannerImage}"'",
    "title" : "'"${welcomeTitle}"'",
    "message" : "'"${welcomeMessage}"'",
    "icon" : "'"${welcomeIcon}"'",
    "iconsize" : "198.0",
    "button1text" : "Continue",
    "infotext" : "'"${scriptVersion}"'",
    "blurscreen" : "true",
    "ontop" : "true",
    "titlefont" : "shadow=true, size=28",
    "messagefont" : "size=14",
    "textfield" : [
        {   "title" : "Position",
            "required" : true,
            "prompt" : "Business Title | Position"
        },
        {   "title" : "User Name",
            "required" : true,
            "prompt" : "User Name"
        },
        {   "title" : "Location",
            "required" : true,
            "prompt" : "Please enter your Location"
        }
    ],
    "selectitems" : [
        {   "title" : "Configuration",
            "default" : "Required",
            "values" : [
                "Required"
            ]
        },  
        {   "title" : "Banner",
            "default" : "The Bay",
            "values" : [
                "The Bay"
            ]
        }
    ],
    "height" : "725"
}
'



####################################################################################################
#
# Setup Your Mac dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Setup Your Mac" dialog Title, Message, Icon and Overlay Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

title="Setting up ${loggedInUserFirstname}'s Mac"
message="Please wait while the following apps are installed …"
bannerImage="https://live.staticflickr.com/65535/52843232549_f2caea6cbf_h.jpg"
#bannerImage="https://img.freepik.com/free-photo/yellow-watercolor-paper_95678-446.jpg"
#bannerText="Setting up ${loggedInUserFirstname}'s Mac"
helpmessage="If you need assistance, please contact Workplace Services:  \n- **Email:** techservices@saks.com  \n\n**Computer Information:**  \n- **Operating System:**  ${macOSproductVersion} (${macOSbuildVersion})  \n- **Serial Number:** ${serialNumber}  \n- **Dialog:** ${dialogVersion}  \n- **Started:** ${timestamp}"
infobox="Analyzing input …" # Customize at "Update Setup Your Mac's infobox"

# Create `overlayicon` from Self Service's custom icon (thanks, @meschwartz!)
xxd -p -s 260 "$(defaults read /Library/Preferences/com.jamfsoftware.jamf self_service_app_path)"/Icon$'\r'/..namedfork/rsrc | xxd -r -p > /var/tmp/overlayicon.icns
overlayicon="https://pbs.twimg.com/profile_images/1428698216074301442/TcF_3JfI_400x400.png"

# Uncomment to use generic, Self Service icon as overlayicon
# overlayicon="https://ics.services.jamfcloud.com/icon/hash_aa63d5813d6ed4846b623ed82acdd1562779bf3716f2d432a8ee533bba8950ee"

# Set initial icon based on whether the Mac is a desktop or laptop
if system_profiler SPPowerDataType | grep -q "Battery Power"; then
    icon="SF=laptopcomputer.and.arrow.down,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
else
    icon="SF=desktopcomputer.and.arrow.down,weight=semibold,colour1=#ef9d51,colour2=#ef7951"
fi

#--bannertext \"$bannerText\" \

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Setup Your Mac" dialog Settings and Features 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogSetupYourMacCMD="$dialogBinary \
--bannerimage \"$bannerImage\" \
--title \"$title\" \
--message \"$message\" \
--helpmessage \"$helpmessage\" \
--icon \"$icon\" \
--infobox \"${infobox}\" \
--progress \
--progresstext \"Initializing configuration …\" \
--button1text \"Wait\" \
--button1disabled \
--infotext \"$scriptVersion\" \
--titlefont 'shadow=true, size=40' \
--messagefont 'size=14' \
--height '780' \
--position 'centre' \
--blurscreen \
--ontop \
--overlayicon \"$overlayicon\" \
--quitkey k \
--commandfile \"$setupYourMacCommandFile\" "



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# "Setup Your Mac" policies to execute (Thanks, Obi-@smithjw!)
#
# For each configuration step, specify:
# - listitem: The text to be displayed in the list
# - icon: The hash of the icon to be displayed on the left
#   - See: https://vimeo.com/772998915
# - progresstext: The text to be displayed below the progress bar
# - trigger: The Jamf Pro Policy Custom Event Name
# - validation: [ {absolute path} | Local | Remote | None ]
#   See: https://snelson.us/2023/01/setup-your-mac-validation/
#       - {absolute path} (simulates pre-v1.6.0 behavior, for example: "/Applications/Microsoft Teams.app/Contents/Info.plist")
#       - Local (for validation within this script, for example: "filevault")
#       - Remote (for validation via a single-script Jamf Pro policy, for example: "symvGlobalProtect")
#       - None (for triggers which don't require validation, for example: recon; always evaluates as successful)
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Thanks, @wakco: If you would prefer to get your policyJSON externally replace it with:
#  - policyJSON="$(cat /path/to/file.json)" # For getting from a file, replacing /path/to/file.json with the path to your file, or
#  - policyJSON="$(curl -sL https://server.name/jsonquery)" # For a URL, replacing https://server.name/jsonquery with the URL of your file.
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
# Thanks, @astrugatch: I added this line to global variables:
# jsonURL=${10} # URL Hosting JSON for policy_array
#
# And this line replaces the entirety of the policy_array (~ line 503):
# policy_array=("$(curl -sL $jsonURL)")
#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# shellcheck disable=SC1112 # use literal slanted single quotes for typographic reasons
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# The fully qualified domain name of the server which hosts your icons, including any required sub-directories
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

setupYourMacPolicyArrayIconPrefixUrl="https://ics.services.jamfcloud.com/icon/hash_"


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Select `policyJSON` based on Configuration selected in "Welcome" dialog (thanks, @drtaru!)
# shellcheck disable=SC1112 # use literal slanted single quotes for typographic reasons
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function policyJSONConfiguration() {

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "WELCOME DIALOG: # # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    updateScriptLog "WELCOME DIALOG: PolicyJSON Configuration: $symConfiguration"

    case ${symConfiguration} in

        "Required" )

            policyJSON='
            {
                "steps": [
                    {
                        "listitem": "Network Speed Test",
                        "icon": "8f05a2f82307e379469e446633f53a9c9a7864ab156cacd5d736b08ea13295eb",
                        "progresstext": "Running Speed Test …",
                        "trigger_list": [
                            {
                                "trigger": "speed",
                                "validation": "None"
                            },
                            {
                                "trigger": "speed",
                                "validation": "Local"
                            }                            
                        ]
                    },                    
                    {
                        "listitem": "Initial Configuration",
                        "icon": "4723e3e341a7e11e6881e418cf91b157fcc081bdb8948697750e5da3562df728",
                        "progresstext": "Initializing Configuration …",
                        "trigger_list": [
                            {
                                "trigger": "remove-apps",
                                "validation": "None"
                            },
                            {
                                "trigger": "remove-jclogin",
                                "validation": "None"
                            },
                            {
                                "trigger": "thebay-rename",
                                "validation": "None"
                            }
                        ]
                    
                    },                                                    
                    {
                        "listitem": "Rosetta",
                        "icon": "8bac19160fabb0c8e7bac97b37b51d2ac8f38b7100b6357642d9505645d37b52",
                        "progresstext": "Rosetta enables a Mac with Apple silicon to use apps built for a Mac with an Intel processor.",
                        "trigger_list": [
                            {
                                "trigger": "rosetta",
                                "validation": "None"
                            },
                            {
                                "trigger": "rosetta",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "FileVault Disk Encryption",
                        "icon": "f9ba35bd55488783456d64ec73372f029560531ca10dfa0e8154a46d7732b913",
                        "progresstext": "FileVault is built-in to macOS and provides full-disk encryption to help prevent unauthorized access to your Mac.",
                        "trigger_list": [
                            {
                                "trigger": "filevault",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "Crowdstrike",
                        "icon": "9023a5e9c381f41b4dee0b32b173c8c2f09b4b25c9312c4d1d92421e0491a773",
                        "progresstext": "You’ll enjoy next-gen protection with Crowdstrike which doesn’t rely on signatures to catch malware.",
                        "trigger_list": [
                            {
                                "trigger": "thebaycrowdstrike",
                                "validation": "/Applications/Falcon.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Printer Drivers",
                        "icon": "b87e8b74cacee853900e16c51e0669b335a4fcd81eb735f3b60bbf353f5160a2",
                        "progresstext": "Printer Driver",
                        "trigger_list": [
                            {
                                "trigger": "printerdrivers",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Splashtop",
                        "icon": "190e2b728e50e2bb4ef0abf1c2c5305faebb8153ceb181857199f0e0efad942c",
                        "progresstext": "Reach out to your PBP for any questions about benefits",
                        "trigger_list": [
                            {
                                "trigger": "thebaysplashtop",
                                "validation": "/Applications/Splashtop Streamer.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Cisco Anyconnect",
                        "icon": "864d3d9aced7a1c36f21e05b68a44e04daa6be47021911029a95004c4e6eb44a",
                        "progresstext": "Use Cisco Anyconnect to establish a Virtual Private Network (VPN) connection to HBC headquarters.",
                        "trigger_list": [
                            {
                                "trigger": "ciscoanyconnect",
                                "validation": "/Applications/Cisco/Cisco AnyConnect Socket Filter.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Google Drive",
                        "icon": "8c04999d2f6b432f0a31a5bb23193b30f6a64e364a54421817deba986d632bc2",
                        "progresstext": "Safely store your files and access them from any device",
                        "trigger_list": [
                            {
                                "trigger": "googledrive",
                                "validation": "/Applications/Google Drive.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Adobe Creative Cloud",
                        "icon": "25ae65f32ea74dd19864ba07b39cab5e120443c699ab968b2e39c0ac03f8c41c",
                        "progresstext": "Enjoy the collection of creative desktop and mobile tools in Adobe Creative Cloud.",
                        "trigger_list": [
                            {
                                "trigger": "adobecreativecloud",
                                "validation": "/Library/Logs/CreativeCloud/ACC/ACC.log"
                            }
                        ]
                    },
                    {
                        "listitem": "Zoom",
                        "icon": "3686d4204bc73ae47563f87fd57484ee5aab3971c1d62ec545939168abf2d7e7",
                        "progresstext": "Use Zoom to meet with your team and join the company all-hands",
                        "trigger_list": [
                            {
                                "trigger": "zoom",
                                "validation": "/Applications/zoom.us.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Zoom Auto Allow Notifications",
                        "icon": "3686d4204bc73ae47563f87fd57484ee5aab3971c1d62ec545939168abf2d7e7",
                        "progresstext": "Setting Zoom notifications to banners",
                        "trigger_list": [
                            {
                                "trigger": "allowzoom",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Adobe Acrobat Reader",
                        "icon": "988b669ca27eab93a9bcd53bb7e2873fb98be4eaa95ae8974c14d611bea1d95f",
                        "progresstext": "Views, prints, and comments on PDF documents, and connects to Adobe Document Cloud.",
                        "trigger_list": [
                            {
                                "trigger": "adobeAcrobatReader",
                                "validation": "/Applications/Adobe Acrobat Reader.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Branding",
                        "icon": "ab3186d1dbe23c73a1ace0ff09f1208dd65ae7f7733248e4a1bcbb008563f258",
                        "progresstext": "Downloading some files",
                        "trigger_list": [
                            {
                                "trigger": "googlechrome",
                                "validation": "/Applications/Google Chrome.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Google Chrome",
                        "icon": "12d3d198f40ab2ac237cff3b5cb05b09f7f26966d6dffba780e4d4e5325cc701",
                        "progresstext": "Google Chrome is a browser that combines a minimal design with sophisticated technology to make the Web faster.",
                        "trigger_list": [
                            {
                                "trigger": "googlechrome",
                                "validation": "/Applications/Google Chrome.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Login Icon",
                        "icon": "084bc401d9232d388b40c7bbc0d1b40f6846957a0390b0e98c0291bec2de85f5",
                        "progresstext": "Setting Login Icon …",
                        "trigger_list": [
                            {
                                "trigger": "thebayloginicon",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Background",
                        "icon": "49a7e00a36b7859e1086e860af6c42f119090822b531eb08bd9e63be2d31c2d8",
                        "progresstext": "Setting Desktop Background …",
                        "trigger_list": [
                            {
                                "trigger": "thebaydesktoppr",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Dock",
                        "icon": "64b2ad38554c0b50c986123e0560f3605da0c7931387b1105ec6d7e8ca859b0f",
                        "progresstext": "Setting The Bay Dock …",
                        "trigger_list": [
                            {
                                "trigger": "thebaydock",
                                "validation": "None"
                            }
                        ]
                    },                   
                    {
                        "listitem": "Final Configuration",
                        "icon": "4723e3e341a7e11e6881e418cf91b157fcc081bdb8948697750e5da3562df728",
                        "progresstext": "Finalizing Configuration …",
                        "trigger_list": [
                            {
                                "trigger": "assign-user",
                                "validation": "None"
                            },
                            {
                                "trigger": "uninstall-depnotify-installers",
                                "validation": "None"
                            }
                        ]
                    
                    },
                    {
                        "listitem": "Computer Inventory",
                        "icon": "ff2147a6c09f5ef73d1c4406d00346811a9c64c0b6b7f36eb52fcb44943d26f9",
                        "progresstext": "A listing of your Mac’s apps and settings — its inventory — is sent automatically to the Jamf Pro server daily.",
                        "trigger_list": [
                            {
                                "trigger": "recon",
                                "validation": "None"
                            }
                        ]
                    }
                ]
            }
            '
            ;;


        "Recommended" )

            policyJSON='
            {
                "steps": [
                    {
                        "listitem": "Network Speed Test",
                        "icon": "8f05a2f82307e379469e446633f53a9c9a7864ab156cacd5d736b08ea13295eb",
                        "progresstext": "Running Speed Test …",
                        "trigger_list": [
                            {
                                "trigger": "speed",
                                "validation": "None"
                            },
                            {
                                "trigger": "speed",
                                "validation": "Local"
                            }                            
                        ]
                    },                    
                    {
                        "listitem": "Initial Configuration",
                        "icon": "4723e3e341a7e11e6881e418cf91b157fcc081bdb8948697750e5da3562df728",
                        "progresstext": "Initializing Configuration …",
                        "trigger_list": [
                            {
                                "trigger": "remove-apps",
                                "validation": "None"
                            },
                            {
                                "trigger": "remove-jclogin",
                                "validation": "None"
                            },
                            {
                                "trigger": "thebay-rename",
                                "validation": "None"
                            }
                        ]
                    
                    },                                                    
                    {
                        "listitem": "Rosetta",
                        "icon": "8bac19160fabb0c8e7bac97b37b51d2ac8f38b7100b6357642d9505645d37b52",
                        "progresstext": "Rosetta enables a Mac with Apple silicon to use apps built for a Mac with an Intel processor.",
                        "trigger_list": [
                            {
                                "trigger": "rosetta",
                                "validation": "None"
                            },
                            {
                                "trigger": "rosetta",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "FileVault Disk Encryption",
                        "icon": "f9ba35bd55488783456d64ec73372f029560531ca10dfa0e8154a46d7732b913",
                        "progresstext": "FileVault is built-in to macOS and provides full-disk encryption to help prevent unauthorized access to your Mac.",
                        "trigger_list": [
                            {
                                "trigger": "filevault",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "Crowdstrike",
                        "icon": "9023a5e9c381f41b4dee0b32b173c8c2f09b4b25c9312c4d1d92421e0491a773",
                        "progresstext": "You’ll enjoy next-gen protection with Crowdstrike which doesn’t rely on signatures to catch malware.",
                        "trigger_list": [
                            {
                                "trigger": "thebaycrowdstrike",
                                "validation": "/Applications/Falcon.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Printer Drivers",
                        "icon": "b87e8b74cacee853900e16c51e0669b335a4fcd81eb735f3b60bbf353f5160a2",
                        "progresstext": "Printer Driver",
                        "trigger_list": [
                            {
                                "trigger": "printerdrivers",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Splashtop",
                        "icon": "190e2b728e50e2bb4ef0abf1c2c5305faebb8153ceb181857199f0e0efad942c",
                        "progresstext": "Reach out to your PBP for any questions about benefits",
                        "trigger_list": [
                            {
                                "trigger": "thebaysplashtop",
                                "validation": "/Applications/Splashtop Streamer.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Cisco Anyconnect",
                        "icon": "864d3d9aced7a1c36f21e05b68a44e04daa6be47021911029a95004c4e6eb44a",
                        "progresstext": "Use Cisco Anyconnect to establish a Virtual Private Network (VPN) connection to HBC headquarters.",
                        "trigger_list": [
                            {
                                "trigger": "ciscoanyconnect",
                                "validation": "/Applications/Cisco/Cisco AnyConnect Socket Filter.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Google Drive",
                        "icon": "8c04999d2f6b432f0a31a5bb23193b30f6a64e364a54421817deba986d632bc2",
                        "progresstext": "Safely store your files and access them from any device",
                        "trigger_list": [
                            {
                                "trigger": "googledrive",
                                "validation": "/Applications/Google Drive.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Adobe Creative Cloud",
                        "icon": "25ae65f32ea74dd19864ba07b39cab5e120443c699ab968b2e39c0ac03f8c41c",
                        "progresstext": "Enjoy the collection of creative desktop and mobile tools in Adobe Creative Cloud.",
                        "trigger_list": [
                            {
                                "trigger": "adobecreativecloud",
                                "validation": "/Library/Logs/CreativeCloud/ACC/ACC.log"
                            }
                        ]
                    },
                    {
                        "listitem": "Zoom",
                        "icon": "3686d4204bc73ae47563f87fd57484ee5aab3971c1d62ec545939168abf2d7e7",
                        "progresstext": "Use Zoom to meet with your team and join the company all-hands",
                        "trigger_list": [
                            {
                                "trigger": "zoom",
                                "validation": "/Applications/zoom.us.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Zoom Auto Allow Notifications",
                        "icon": "3686d4204bc73ae47563f87fd57484ee5aab3971c1d62ec545939168abf2d7e7",
                        "progresstext": "Setting Zoom notifications to banners",
                        "trigger_list": [
                            {
                                "trigger": "allowzoom",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Adobe Acrobat Reader",
                        "icon": "988b669ca27eab93a9bcd53bb7e2873fb98be4eaa95ae8974c14d611bea1d95f",
                        "progresstext": "Views, prints, and comments on PDF documents, and connects to Adobe Document Cloud.",
                        "trigger_list": [
                            {
                                "trigger": "adobeAcrobatReader",
                                "validation": "/Applications/Adobe Acrobat Reader.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Branding",
                        "icon": "ab3186d1dbe23c73a1ace0ff09f1208dd65ae7f7733248e4a1bcbb008563f258",
                        "progresstext": "Downloading some files",
                        "trigger_list": [
                            {
                                "trigger": "googlechrome",
                                "validation": "/Applications/Google Chrome.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Google Chrome",
                        "icon": "12d3d198f40ab2ac237cff3b5cb05b09f7f26966d6dffba780e4d4e5325cc701",
                        "progresstext": "Google Chrome is a browser that combines a minimal design with sophisticated technology to make the Web faster.",
                        "trigger_list": [
                            {
                                "trigger": "googlechrome",
                                "validation": "/Applications/Google Chrome.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Login Icon",
                        "icon": "084bc401d9232d388b40c7bbc0d1b40f6846957a0390b0e98c0291bec2de85f5",
                        "progresstext": "Setting Login Icon …",
                        "trigger_list": [
                            {
                                "trigger": "thebayloginicon",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Background",
                        "icon": "49a7e00a36b7859e1086e860af6c42f119090822b531eb08bd9e63be2d31c2d8",
                        "progresstext": "Setting Desktop Background …",
                        "trigger_list": [
                            {
                                "trigger": "thebaydesktoppr",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Dock",
                        "icon": "64b2ad38554c0b50c986123e0560f3605da0c7931387b1105ec6d7e8ca859b0f",
                        "progresstext": "Setting The Bay Dock …",
                        "trigger_list": [
                            {
                                "trigger": "thebaydock",
                                "validation": "None"
                            }
                        ]
                    },                   
                    {
                        "listitem": "Final Configuration",
                        "icon": "4723e3e341a7e11e6881e418cf91b157fcc081bdb8948697750e5da3562df728",
                        "progresstext": "Finalizing Configuration …",
                        "trigger_list": [
                            {
                                "trigger": "assign-user",
                                "validation": "None"
                            },
                            {
                                "trigger": "uninstall-depnotify-installers",
                                "validation": "None"
                            }
                        ]
                    
                    },
                    {
                        "listitem": "Computer Inventory",
                        "icon": "ff2147a6c09f5ef73d1c4406d00346811a9c64c0b6b7f36eb52fcb44943d26f9",
                        "progresstext": "A listing of your Mac’s apps and settings — its inventory — is sent automatically to the Jamf Pro server daily.",
                        "trigger_list": [
                            {
                                "trigger": "recon",
                                "validation": "None"
                            }
                        ]
                    }
                ]
            }
            '
            ;;


        "Complete" )

            policyJSON='
            {
                "steps": [
                    {
                        "listitem": "Network Speed Test",
                        "icon": "8f05a2f82307e379469e446633f53a9c9a7864ab156cacd5d736b08ea13295eb",
                        "progresstext": "Running Speed Test …",
                        "trigger_list": [
                            {
                                "trigger": "speed",
                                "validation": "None"
                            },
                            {
                                "trigger": "speed",
                                "validation": "Local"
                            }                            
                        ]
                    },                    
                    {
                        "listitem": "Initial Configuration",
                        "icon": "4723e3e341a7e11e6881e418cf91b157fcc081bdb8948697750e5da3562df728",
                        "progresstext": "Initializing Configuration …",
                        "trigger_list": [
                            {
                                "trigger": "remove-apps",
                                "validation": "None"
                            },
                            {
                                "trigger": "remove-jclogin",
                                "validation": "None"
                            },
                            {
                                "trigger": "thebay-rename",
                                "validation": "None"
                            }
                        ]
                    
                    },                                                    
                    {
                        "listitem": "Rosetta",
                        "icon": "8bac19160fabb0c8e7bac97b37b51d2ac8f38b7100b6357642d9505645d37b52",
                        "progresstext": "Rosetta enables a Mac with Apple silicon to use apps built for a Mac with an Intel processor.",
                        "trigger_list": [
                            {
                                "trigger": "rosetta",
                                "validation": "None"
                            },
                            {
                                "trigger": "rosetta",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "FileVault Disk Encryption",
                        "icon": "f9ba35bd55488783456d64ec73372f029560531ca10dfa0e8154a46d7732b913",
                        "progresstext": "FileVault is built-in to macOS and provides full-disk encryption to help prevent unauthorized access to your Mac.",
                        "trigger_list": [
                            {
                                "trigger": "filevault",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "Crowdstrike",
                        "icon": "9023a5e9c381f41b4dee0b32b173c8c2f09b4b25c9312c4d1d92421e0491a773",
                        "progresstext": "You’ll enjoy next-gen protection with Crowdstrike which doesn’t rely on signatures to catch malware.",
                        "trigger_list": [
                            {
                                "trigger": "thebaycrowdstrike",
                                "validation": "/Applications/Falcon.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Printer Drivers",
                        "icon": "b87e8b74cacee853900e16c51e0669b335a4fcd81eb735f3b60bbf353f5160a2",
                        "progresstext": "Printer Driver",
                        "trigger_list": [
                            {
                                "trigger": "printerdrivers",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Splashtop",
                        "icon": "190e2b728e50e2bb4ef0abf1c2c5305faebb8153ceb181857199f0e0efad942c",
                        "progresstext": "Reach out to your PBP for any questions about benefits",
                        "trigger_list": [
                            {
                                "trigger": "thebaysplashtop",
                                "validation": "/Applications/Splashtop Streamer.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Cisco Anyconnect",
                        "icon": "864d3d9aced7a1c36f21e05b68a44e04daa6be47021911029a95004c4e6eb44a",
                        "progresstext": "Use Cisco Anyconnect to establish a Virtual Private Network (VPN) connection to HBC headquarters.",
                        "trigger_list": [
                            {
                                "trigger": "ciscoanyconnect",
                                "validation": "/Applications/Cisco/Cisco AnyConnect Socket Filter.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Google Drive",
                        "icon": "8c04999d2f6b432f0a31a5bb23193b30f6a64e364a54421817deba986d632bc2",
                        "progresstext": "Safely store your files and access them from any device",
                        "trigger_list": [
                            {
                                "trigger": "googledrive",
                                "validation": "/Applications/Google Drive.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Adobe Creative Cloud",
                        "icon": "25ae65f32ea74dd19864ba07b39cab5e120443c699ab968b2e39c0ac03f8c41c",
                        "progresstext": "Enjoy the collection of creative desktop and mobile tools in Adobe Creative Cloud.",
                        "trigger_list": [
                            {
                                "trigger": "adobecreativecloud",
                                "validation": "/Library/Logs/CreativeCloud/ACC/ACC.log"
                            }
                        ]
                    },
                    {
                        "listitem": "Zoom",
                        "icon": "3686d4204bc73ae47563f87fd57484ee5aab3971c1d62ec545939168abf2d7e7",
                        "progresstext": "Use Zoom to meet with your team and join the company all-hands",
                        "trigger_list": [
                            {
                                "trigger": "zoom",
                                "validation": "/Applications/zoom.us.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Zoom Auto Allow Notifications",
                        "icon": "3686d4204bc73ae47563f87fd57484ee5aab3971c1d62ec545939168abf2d7e7",
                        "progresstext": "Setting Zoom notifications to banners",
                        "trigger_list": [
                            {
                                "trigger": "allowzoom",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Adobe Acrobat Reader",
                        "icon": "988b669ca27eab93a9bcd53bb7e2873fb98be4eaa95ae8974c14d611bea1d95f",
                        "progresstext": "Views, prints, and comments on PDF documents, and connects to Adobe Document Cloud.",
                        "trigger_list": [
                            {
                                "trigger": "adobeAcrobatReader",
                                "validation": "/Applications/Adobe Acrobat Reader.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Branding",
                        "icon": "ab3186d1dbe23c73a1ace0ff09f1208dd65ae7f7733248e4a1bcbb008563f258",
                        "progresstext": "Downloading some files",
                        "trigger_list": [
                            {
                                "trigger": "googlechrome",
                                "validation": "/Applications/Google Chrome.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Google Chrome",
                        "icon": "12d3d198f40ab2ac237cff3b5cb05b09f7f26966d6dffba780e4d4e5325cc701",
                        "progresstext": "Google Chrome is a browser that combines a minimal design with sophisticated technology to make the Web faster.",
                        "trigger_list": [
                            {
                                "trigger": "googlechrome",
                                "validation": "/Applications/Google Chrome.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Login Icon",
                        "icon": "084bc401d9232d388b40c7bbc0d1b40f6846957a0390b0e98c0291bec2de85f5",
                        "progresstext": "Setting Login Icon …",
                        "trigger_list": [
                            {
                                "trigger": "thebayloginicon",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Background",
                        "icon": "49a7e00a36b7859e1086e860af6c42f119090822b531eb08bd9e63be2d31c2d8",
                        "progresstext": "Setting Desktop Background …",
                        "trigger_list": [
                            {
                                "trigger": "thebaydesktoppr",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Dock",
                        "icon": "64b2ad38554c0b50c986123e0560f3605da0c7931387b1105ec6d7e8ca859b0f",
                        "progresstext": "Setting The Bay Dock …",
                        "trigger_list": [
                            {
                                "trigger": "thebaydock",
                                "validation": "None"
                            }
                        ]
                    },                   
                    {
                        "listitem": "Final Configuration",
                        "icon": "4723e3e341a7e11e6881e418cf91b157fcc081bdb8948697750e5da3562df728",
                        "progresstext": "Finalizing Configuration …",
                        "trigger_list": [
                            {
                                "trigger": "assign-user",
                                "validation": "None"
                            },
                            {
                                "trigger": "uninstall-depnotify-installers",
                                "validation": "None"
                            }
                        ]
                    
                    },
                    {
                        "listitem": "Computer Inventory",
                        "icon": "ff2147a6c09f5ef73d1c4406d00346811a9c64c0b6b7f36eb52fcb44943d26f9",
                        "progresstext": "A listing of your Mac’s apps and settings — its inventory — is sent automatically to the Jamf Pro server daily.",
                        "trigger_list": [
                            {
                                "trigger": "recon",
                                "validation": "None"
                            }
                        ]
                    }
                ]
            }
            '
            ;;

        * ) # Catch-all (i.e., used when `welcomeDialog` is set to `video` or `false`)

            policyJSON='
            {
                "steps": [
                    {
                        "listitem": "Network Speed Test",
                        "icon": "8f05a2f82307e379469e446633f53a9c9a7864ab156cacd5d736b08ea13295eb",
                        "progresstext": "Running Speed Test …",
                        "trigger_list": [
                            {
                                "trigger": "speed",
                                "validation": "None"
                            },
                            {
                                "trigger": "speed",
                                "validation": "Local"
                            }                            
                        ]
                    },                    
                    {
                        "listitem": "Initial Configuration",
                        "icon": "4723e3e341a7e11e6881e418cf91b157fcc081bdb8948697750e5da3562df728",
                        "progresstext": "Initializing Configuration …",
                        "trigger_list": [
                            {
                                "trigger": "remove-apps",
                                "validation": "None"
                            },
                            {
                                "trigger": "remove-jclogin",
                                "validation": "None"
                            },
                            {
                                "trigger": "thebay-rename",
                                "validation": "None"
                            }
                        ]
                    
                    },                                                    
                    {
                        "listitem": "Rosetta",
                        "icon": "8bac19160fabb0c8e7bac97b37b51d2ac8f38b7100b6357642d9505645d37b52",
                        "progresstext": "Rosetta enables a Mac with Apple silicon to use apps built for a Mac with an Intel processor.",
                        "trigger_list": [
                            {
                                "trigger": "rosetta",
                                "validation": "None"
                            },
                            {
                                "trigger": "rosetta",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "FileVault Disk Encryption",
                        "icon": "f9ba35bd55488783456d64ec73372f029560531ca10dfa0e8154a46d7732b913",
                        "progresstext": "FileVault is built-in to macOS and provides full-disk encryption to help prevent unauthorized access to your Mac.",
                        "trigger_list": [
                            {
                                "trigger": "filevault",
                                "validation": "Local"
                            }
                        ]
                    },
                    {
                        "listitem": "Crowdstrike",
                        "icon": "9023a5e9c381f41b4dee0b32b173c8c2f09b4b25c9312c4d1d92421e0491a773",
                        "progresstext": "You’ll enjoy next-gen protection with Crowdstrike which doesn’t rely on signatures to catch malware.",
                        "trigger_list": [
                            {
                                "trigger": "thebaycrowdstrike",
                                "validation": "/Applications/Falcon.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Printer Drivers",
                        "icon": "b87e8b74cacee853900e16c51e0669b335a4fcd81eb735f3b60bbf353f5160a2",
                        "progresstext": "Installing Printer Drivers …",
                        "trigger_list": [
                            {
                                "trigger": "printerdrivers",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Capture One 23",
                        "icon": "05791c3730d7663180eb2ae89c851c6af2f42fff63597a653f01e9962d4c2961",
                        "progresstext": "Capture Ones 23 installing …",
                        "trigger_list": [
                            {
                                "trigger": "CaptureOne23",
                                "validation": "/Applications/Capture One 23.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Nikon NX Tether",
                        "icon": "d4f0e6dfa9f7a7f8e55e9e6d49284b1fa9f421f428568a3b17f8bf0fe4ed8966",
                        "progresstext": "Nikon NX Tether …",
                        "trigger_list": [
                            {
                                "trigger": "nxtether",
                                "validation": "/Applications/Nikon Software/NXTether/NXTether.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Nikon NX Studio",
                        "icon": "d4f0e6dfa9f7a7f8e55e9e6d49284b1fa9f421f428568a3b17f8bf0fe4ed8966",
                        "progresstext": "NX Studio is always up-to-date with the latest and most precise Nikon camera information …",
                        "trigger_list": [
                            {
                                "trigger": "nxstudio",
                                "validation": "/Applications/Nikon Software/NX Studio/NX Studio.app/Contents/Info.plist"
                            }
                        ]
                    },                    
                    {
                        "listitem": "Splashtop",
                        "icon": "190e2b728e50e2bb4ef0abf1c2c5305faebb8153ceb181857199f0e0efad942c",
                        "progresstext": "Reach out to your PBP for any questions about benefits",
                        "trigger_list": [
                            {
                                "trigger": "thebaysplashtop",
                                "validation": "/Applications/Splashtop Streamer.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Google Drive",
                        "icon": "8c04999d2f6b432f0a31a5bb23193b30f6a64e364a54421817deba986d632bc2",
                        "progresstext": "Safely store your files and access them from any device",
                        "trigger_list": [
                            {
                                "trigger": "googledrive",
                                "validation": "/Applications/Google Drive.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Zoom",
                        "icon": "3686d4204bc73ae47563f87fd57484ee5aab3971c1d62ec545939168abf2d7e7",
                        "progresstext": "Use Zoom to meet with your team and join the company all-hands",
                        "trigger_list": [
                            {
                                "trigger": "zoom",
                                "validation": "/Applications/zoom.us.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Adobe Acrobat Reader",
                        "icon": "988b669ca27eab93a9bcd53bb7e2873fb98be4eaa95ae8974c14d611bea1d95f",
                        "progresstext": "Views, prints, and comments on PDF documents, and connects to Adobe Document Cloud.",
                        "trigger_list": [
                            {
                                "trigger": "adobeAcrobatReader",
                                "validation": "/Applications/Adobe Acrobat Reader.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Zoom Auto Allow Notifications",
                        "icon": "3686d4204bc73ae47563f87fd57484ee5aab3971c1d62ec545939168abf2d7e7",
                        "progresstext": "Setting Zoom notifications to banners",
                        "trigger_list": [
                            {
                                "trigger": "allowzoom",
                                "validation": "None"
                            }
                        ]
                    },                    
                    {
                        "listitem": "Branding",
                        "icon": "ab3186d1dbe23c73a1ace0ff09f1208dd65ae7f7733248e4a1bcbb008563f258",
                        "progresstext": "Downloading some files",
                        "trigger_list": [
                            {
                                "trigger": "thebaylogo",
                                "validation": "/Users/Shared/HB_WALLPAPER.jpg"
                            }
                        ]
                    },
                    {
                        "listitem": "Google Chrome",
                        "icon": "12d3d198f40ab2ac237cff3b5cb05b09f7f26966d6dffba780e4d4e5325cc701",
                        "progresstext": "Google Chrome is a browser that combines a minimal design with sophisticated technology to make the Web faster.",
                        "trigger_list": [
                            {
                                "trigger": "googlechrome",
                                "validation": "/Applications/Google Chrome.app/Contents/Info.plist"
                            }
                        ]
                    },
                    {
                        "listitem": "Login Icon",
                        "icon": "084bc401d9232d388b40c7bbc0d1b40f6846957a0390b0e98c0291bec2de85f5",
                        "progresstext": "Setting Login Icon …",
                        "trigger_list": [
                            {
                                "trigger": "thebayloginicon",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Background",
                        "icon": "49a7e00a36b7859e1086e860af6c42f119090822b531eb08bd9e63be2d31c2d8",
                        "progresstext": "Setting Desktop Background …",
                        "trigger_list": [
                            {
                                "trigger": "thebaydesktoppr",
                                "validation": "None"
                            }
                        ]
                    },
                    {
                        "listitem": "Dock",
                        "icon": "64b2ad38554c0b50c986123e0560f3605da0c7931387b1105ec6d7e8ca859b0f",
                        "progresstext": "Setting The Bay Dock …",
                        "trigger_list": [
                            {
                                "trigger": "thebaydock",
                                "validation": "None"
                            }
                        ]
                    },                   
                    {
                        "listitem": "Final Configuration",
                        "icon": "4723e3e341a7e11e6881e418cf91b157fcc081bdb8948697750e5da3562df728",
                        "progresstext": "Finalizing Configuration …",
                        "trigger_list": [
                            {
                                "trigger": "assign-user",
                                "validation": "None"
                            },
                            {
                                "trigger": "uninstall-setupyourmac-installers",
                                "validation": "None"
                            }
                        ]
                    
                    },
                    {
                        "listitem": "Computer Inventory",
                        "icon": "ff2147a6c09f5ef73d1c4406d00346811a9c64c0b6b7f36eb52fcb44943d26f9",
                        "progresstext": "A listing of your Mac’s apps and settings — its inventory — is sent automatically to the Jamf Pro server daily.",
                        "trigger_list": [
                            {
                                "trigger": "recon",
                                "validation": "None"
                            }
                        ]
                    }
                ]
            }
            '
            ;;


    esac

}



####################################################################################################
#
# Failure dialog
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Failure" dialog Title, Message and Icon
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

failureTitle="Failure Detected"
failureMessage="Placeholder message; update in the 'finalise' function"
failureIcon="SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# "Failure" dialog Settings and Features
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

dialogFailureCMD="$dialogBinary \
--moveable \
--title \"$failureTitle\" \
--message \"$failureMessage\" \
--icon \"$failureIcon\" \
--iconsize 125 \
--width 625 \
--height 525 \
--position topright \
--button1text \"Close\" \
--infotext \"$scriptVersion\" \
--titlefont 'size=22' \
--messagefont 'size=14' \
--overlayicon \"$overlayicon\" \
--commandfile \"$failureCommandFile\" "



#------------------------ With the execption of the `finalise` function, -------------------------#
#------------------------ edits below these line are optional. -----------------------------------#



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Dynamically set `button1text` based on the value of `completionActionOption`
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

case ${completionActionOption} in

    "Shut Down" )
        button1textCompletionActionOption="Shutting Down …"
        progressTextCompletionAction="shut down and "
        ;;

    "Shut Down "* )
        button1textCompletionActionOption="Shut Down"
        progressTextCompletionAction="shut down and "
        ;;

    "Restart" )
        button1textCompletionActionOption="Restarting …"
        progressTextCompletionAction="restart and "
        ;;

    "Restart "* )
        button1textCompletionActionOption="Restart"
        progressTextCompletionAction="restart and "
        ;;

    "Log Out" )
        button1textCompletionActionOption="Logging Out …"
        progressTextCompletionAction="log out and "
        ;;

    "Log Out "* )
        button1textCompletionActionOption="Log Out"
        progressTextCompletionAction="log out and "
        ;;

    "Sleep"* )
        button1textCompletionActionOption="Close"
        progressTextCompletionAction=""
        ;;

    "Quit" )
        button1textCompletionActionOption="Quit"
        progressTextCompletionAction=""
        ;;

    * )
        button1textCompletionActionOption="Close"
        progressTextCompletionAction=""
        ;;

esac



####################################################################################################
#
# Functions
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Run command as logged-in user (thanks, @scriptingosx!)
# shellcheck disable=SC2145
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function runAsUser() {

    updateScriptLog "Run \"$@\" as \"$loggedInUserID\" … "
    launchctl asuser "$loggedInUserID" sudo -u "$loggedInUser" "$@"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update the "Welcome" dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateWelcome(){
    updateScriptLog "WELCOME DIALOG: $1"
    echo "$1" >> "$welcomeCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update the "Setup Your Mac" dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateSetupYourMac() {
    updateScriptLog "SETUP YOUR MAC DIALOG: $1"
    echo "$1" >> "$setupYourMacCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update the "Failure" dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function dialogUpdateFailure(){
    updateScriptLog "FAILURE DIALOG: $1"
    echo "$1" >> "$failureCommandFile"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Finalise User Experience
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function finalise(){

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    if [[ "${jamfProPolicyTriggerFailure}" == "failed" ]]; then

        killProcess "caffeinate"
        dialogUpdateSetupYourMac "title: Sorry ${loggedInUserFirstname}, something went sideways"
        dialogUpdateSetupYourMac "icon: SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"
        dialogUpdateSetupYourMac "progresstext: Failures detected. Please click Continue for troubleshooting information."
        dialogUpdateSetupYourMac "button1text: Continue …"
        dialogUpdateSetupYourMac "button1: enable"
        dialogUpdateSetupYourMac "progress: reset"

        # Wait for user-acknowledgment due to detected failure
        wait

        dialogUpdateSetupYourMac "quit:"
        eval "${dialogFailureCMD}" & sleep 0.3

        updateScriptLog "\n\n# # #\n# FAILURE DIALOG\n# # #\n"
        updateScriptLog "Jamf Pro Policy Name Failures:"
        updateScriptLog "${jamfProPolicyNameFailures}"

        dialogUpdateFailure "message: A failure has been detected, ${loggedInUserFirstname}.  \n\nPlease complete the following steps:\n1. Reboot and login to your Mac  \n2. Login to Self Service  \n3. Re-run any failed policy listed below  \n\nThe following failed:  \n${jamfProPolicyNameFailures}  \n\n\n\nIf you need assistance, please contact Workplace Services via email at techservices@saks.com or by submitting a Cherwell ticket [here](https://hbc.cherwellondemand.com/CherwellPortal/). "
        dialogUpdateFailure "icon: SF=xmark.circle.fill,weight=bold,colour1=#BB1717,colour2=#F31F1F"
        dialogUpdateFailure "button1text: ${button1textCompletionActionOption}"

        # Wait for user-acknowledgment due to detected failure
        wait

        dialogUpdateFailure "quit:"
        quitScript "1"

    else

        dialogUpdateSetupYourMac "title: ${loggedInUserFirstname}'s Mac is ready!"
        dialogUpdateSetupYourMac "icon: SF=checkmark.circle.fill,weight=bold,colour1=#00ff44,colour2=#075c1e"
        dialogUpdateSetupYourMac "progresstext: Complete! Please ${progressTextCompletionAction}enjoy your new Mac, ${loggedInUserFirstname}!"
        dialogUpdateSetupYourMac "progress: complete"
        dialogUpdateSetupYourMac "button1text: ${button1textCompletionActionOption}"
        dialogUpdateSetupYourMac "button1: enable"

        # If either "wait" or "sleep" has been specified for `completionActionOption`, honor that behavior
        if [[ "${completionActionOption}" == "wait" ]] || [[ "${completionActionOption}" == "[Ss]leep"* ]]; then
            updateScriptLog "Honoring ${completionActionOption} behavior …"
            eval "${completionActionOption}" "${dialogSetupYourMacProcessID}"
        fi

        quitScript "0"

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse JSON via osascript and JavaScript
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function get_json_value() {
    JSON="$1" osascript -l 'JavaScript' \
        -e 'const env = $.NSProcessInfo.processInfo.environment.objectForKey("JSON").js' \
        -e "JSON.parse(env).$2"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Parse JSON via osascript and JavaScript for the Welcome dialog (thanks, @bartreardon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function get_json_value_welcomeDialog() {
    for var in "${@:2}"; do jsonkey="${jsonkey}['${var}']"; done
    JSON="$1" osascript -l 'JavaScript' \
        -e 'const env = $.NSProcessInfo.processInfo.environment.objectForKey("JSON").js' \
        -e "JSON.parse(env)$jsonkey"
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Execute Jamf Pro Policy Custom Events (thanks, @smithjw)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function run_jamf_trigger() {

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    trigger="$1"

    if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then

        updateScriptLog "SETUP YOUR MAC DIALOG: DEBUG MODE: TRIGGER: $jamfBinary policy -trigger $trigger"
        if [[ "$trigger" == "recon" ]]; then
            updateScriptLog "SETUP YOUR MAC DIALOG: DEBUG MODE: RECON: $jamfBinary recon ${reconOptions}"
        fi
        sleep 1

    elif [[ "$trigger" == "recon" ]]; then

        dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Updating …, "
        updateScriptLog "SETUP YOUR MAC DIALOG: Computer inventory, with the following reconOptions: \"${reconOptions}\", will be be executed in the 'confirmPolicyExecution' function …"
        # eval "${jamfBinary} recon ${reconOptions}"

    else

        updateScriptLog "SETUP YOUR MAC DIALOG: RUNNING: $jamfBinary policy -trigger $trigger"
        eval "${jamfBinary} policy -trigger ${trigger}"                                     # Add comment for policy testing
        # eval "${jamfBinary} policy -trigger ${trigger} -verbose | tee -a ${scriptLog}"    # Remove comment for policy testing

    fi

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Confirm Policy Execution
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function confirmPolicyExecution() {

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    trigger="${1}"
    validation="${2}"
    updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: '${trigger}' '${validation}'"

    case ${validation} in

        */* ) # If the validation variable contains a forward slash (i.e., "/"), presume it's a path and check if that path exists on disk
            if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
                updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: DEBUG MODE: Skipping 'run_jamf_trigger ${trigger}'"
                sleep 1
            elif [[ -f "${validation}" ]]; then
                updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: ${validation} exists; skipping 'run_jamf_trigger ${trigger}'"
                previouslyInstalled="true"
            else
                updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: ${validation} does NOT exist; executing 'run_jamf_trigger ${trigger}'"
                previouslyInstalled="false"
                run_jamf_trigger "${trigger}"
            fi
            ;;

        "None" )
            updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: ${validation}"
            if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
                sleep 1
            else
                run_jamf_trigger "${trigger}"
            fi
            ;;

        * )
            updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution Catch-all: ${validation}"
            if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
                sleep 1
            else
                run_jamf_trigger "${trigger}"
            fi
            ;;

    esac

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Validate Policy Result
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function validatePolicyResult() {

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    trigger="${1}"
    validation="${2}"
    updateScriptLog "SETUP YOUR MAC DIALOG: Validate Policy Result: '${trigger}' '${validation}'"

    case ${validation} in

        ###
        # Absolute Path
        # Simulates pre-v1.6.0 behavior, for example: "/Applications/Microsoft Teams.app/Contents/Info.plist"
        ###

        */* ) 
            updateScriptLog "SETUP YOUR MAC DIALOG: Validate Policy Result: Testing for \"$validation\" …"
            if [[ "${previouslyInstalled}" == "true" ]]; then
                dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Previously Installed"
            elif [[ -f "${validation}" ]]; then
                dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Installed"
            else
                dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                jamfProPolicyTriggerFailure="failed"
                exitCode="1"
                jamfProPolicyNameFailures+="• $listitem  \n"
            fi
            ;;



        ###
        # Local
        # Validation within this script, for example: "rosetta" or "filevault"
        ###

        "Local" )
            case ${trigger} in
                rosetta ) 
                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Rosetta 2 … " # Thanks, @smithjw!
                    dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Checking …"
                    arch=$( /usr/bin/arch )
                    if [[ "${arch}" == "arm64" ]]; then
                        # Mac with Apple silicon; check for Rosetta
                        rosettaTest=$( arch -x86_64 /usr/bin/true 2> /dev/null ; echo $? )
                        if [[ "${rosettaTest}" -eq 0 ]]; then
                            # Installed
                            updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Rosetta 2 is installed"
                            dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Running"
                        else
                            # Not Installed
                            updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Rosetta 2 is NOT installed"
                            dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                            jamfProPolicyTriggerFailure="failed"
                            exitCode="1"
                            jamfProPolicyNameFailures+="• $listitem  \n"
                        fi
                    else
                        # Ineligible
                        updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Rosetta 2 is not needed machines is on an Intel chip"
                        dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Not Needed"
                    fi
                    ;;
                filevault )
                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Validate FileVault … "
                    dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Checking …"
                    updateScriptLog "SETUP YOUR MAC DIALOG: Validate Policy Result: Pausing for 5 seconds for FileVault … "
                    sleep 5 # Arbitrary value; tuning needed
                    if [[ -f /Library/Preferences/com.apple.fdesetup.plist ]]; then
                        fileVaultStatus=$( fdesetup status -extended -verbose 2>&1 )
                        case ${fileVaultStatus} in
                            *"FileVault is On."* ) 
                                updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: FileVault: FileVault is On."
                                dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Enabled"
                                ;;
                            *"Deferred enablement appears to be active for user"* )
                                updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: FileVault: Enabled"
                                dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Enabled (next login)"
                                ;;
                            *  )
                                dialogUpdateSetupYourMac "listitem: index: $i, status: error, statustext: Unknown"
                                jamfProPolicyTriggerFailure="failed"
                                exitCode="1"
                                jamfProPolicyNameFailures+="• $listitem  \n"
                                ;;
                        esac
                    else
                        updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: '/Library/Preferences/com.apple.fdesetup.plist' NOT Found"
                        dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                        jamfProPolicyTriggerFailure="failed"
                        exitCode="1"
                        jamfProPolicyNameFailures+="• $listitem  \n"
                    fi
                    ;;
                speed )
                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Validate Network … "
                    dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Checking …"
                    updateScriptLog "SETUP YOUR MAC DIALOG: Validate Policy Result: Pausing for 5 seconds for Network speed test … "
                    sleep 5 # Arbitrary value; tuning needed
                    if [[ -f /Library/Preferences/com.apple.networkd.plist ]]; then
                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Network: Network Connection validated."
                    dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Checked"
                    else
                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: '/Library/Preferences/com.apple.fdesetup.plist' NOT Found"
                    dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                    jamfProPolicyTriggerFailure="failed"
                    exitCode="1"
                    jamfProPolicyNameFailures+="• $listitem  \n"
                    fi
                    ;;
                crowdstrikeEndpointServices )
                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Crowdstrike RTS Status … "
                    dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Checking …"
                    if [[ -d /Applications/Falcon.app ]]; then
                        if [[ -f /Library/LaunchAgents/com.crowdstrike.falcon.UserAgent.plist ]]; then
                            crowdstrikeOnAccessRunning=$( /usr/bin/defaults read /Library/LaunchAgents/com.crowdstrike.falcon.UserAgent.plist OnAccessRunning )
                            case ${crowdstrikeOnAccessRunning} in
                                "0" ) 
                                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Crowdstrike RTS Status: Disabled"
                                    dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                                    jamfProPolicyTriggerFailure="failed"
                                    exitCode="1"
                                    jamfProPolicyNameFailures+="• $listitem  \n"
                                    ;;
                                "1" )
                                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Crowdstrike RTS Status: Enabled"
                                    dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Running"
                                    ;;
                                *  )
                                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Crowdstrike RTS Status: Unknown"
                                    dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Unknown"
                                    jamfProPolicyTriggerFailure="failed"
                                    exitCode="1"
                                    jamfProPolicyNameFailures+="• $listitem  \n"
                                    ;;
                            esac
                        else
                            updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Crowdstrike Not Found"
                            dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                            jamfProPolicyTriggerFailure="failed"
                            exitCode="1"
                            jamfProPolicyNameFailures+="• $listitem  \n"
                        fi
                    else
                        dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                        jamfProPolicyTriggerFailure="failed"
                        exitCode="1"
                        jamfProPolicyNameFailures+="• $listitem  \n"
                    fi
                    ;;
                ciscoanyconnect )
                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Cisco AnyConnect Status … "
                    dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Checking …"
                    if [[ -d /Applications/Cisco ]]; then
                        updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Pausing for 10 seconds to allow Cisco AnyConnect … "
                        sleep 10 # Arbitrary value; tuning needed
                        if [[ -f /Library/LaunchAgents/com.cisco.anyconnect.notification.plist ]]; then
                            globalProtectStatus=$( /usr/libexec/PlistBuddy -c "print :Palo\ Alto\ Networks:GlobalProtect:PanGPS:disable-globalprotect" /Library/Preferences/com.paloaltonetworks.GlobalProtect.settings.plist )
                            case "${globalProtectStatus}" in
                                "0" )
                                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Cisco AnyConnect Status: Enabled"
                                    dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Running"
                                    ;;
                                "1" )
                                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Cisco AnyConnect Status: Disabled"
                                    dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                                    jamfProPolicyTriggerFailure="failed"
                                    exitCode="1"
                                    jamfProPolicyNameFailures+="• $listitem  \n"
                                    ;;
                                *  )
                                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Cisco AnyConnect Status: Unknown"
                                    dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Unknown"
                                    jamfProPolicyTriggerFailure="failed"
                                    exitCode="1"
                                    jamfProPolicyNameFailures+="• $listitem  \n"
                                    ;;
                            esac
                        else
                            updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Result: Cisco AnyConnect Not Found"
                            dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                            jamfProPolicyTriggerFailure="failed"
                            exitCode="1"
                            jamfProPolicyNameFailures+="• $listitem  \n"
                        fi
                    else
                        dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                        jamfProPolicyTriggerFailure="failed"
                        exitCode="1"
                        jamfProPolicyNameFailures+="• $listitem  \n"
                    fi
                    ;;
                * )
                    updateScriptLog "SETUP YOUR MAC DIALOG: Locally Validate Policy Results Local Catch-all: ${validation}"
                    ;;
            esac
            ;;



        ###
        # Remote
        # Validation via a Jamf Pro policy which has a single-script payload, for example: "symvGlobalProtect"
        # See: https://vimeo.com/782561166
        ###

        "Remote" )
            if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
                updateScriptLog "SETUP YOUR MAC DIALOG: DEBUG MODE: Remotely Confirm Policy Execution: Skipping 'run_jamf_trigger ${trigger}'"
                dialogUpdateSetupYourMac "listitem: index: $i, status: error, statustext: Debug Mode Enabled"
                sleep 0.5
            else
                updateScriptLog "SETUP YOUR MAC DIALOG: Remotely Validate '${trigger}' '${validation}'"
                dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Checking …"
                result=$( "${jamfBinary}" policy -trigger "${trigger}" | grep "Script result:" )
                if [[ "${result}" == *"Running"* ]]; then
                    dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Running"
                else
                    dialogUpdateSetupYourMac "listitem: index: $i, status: fail, statustext: Failed"
                    jamfProPolicyTriggerFailure="failed"
                    exitCode="1"
                    jamfProPolicyNameFailures+="• $listitem  \n"
                fi
            fi
            ;;



        ###
        # None (always evaluates as successful)
        # For triggers which don't require validation, for example: recon
        ###

        "None" )
            # Output Line Number in `verbose` Debug Mode         
            if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi
            updateScriptLog "SETUP YOUR MAC DIALOG: Confirm Policy Execution: ${validation}"
            dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Installed"
            if [[ "${trigger}" == "recon" ]]; then
                dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Updating …, "
                updateScriptLog "SETUP YOUR MAC DIALOG: Updating computer inventory with the following reconOptions: \"${reconOptions}\" …"
                if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
                    updateScriptLog "SETUP YOUR MAC DIALOG: DEBUG MODE: eval ${jamfBinary} recon ${reconOptions}"
                else
                    eval "${jamfBinary} recon ${reconOptions}"
                fi
                dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Updated"
            fi
            if [[ "${trigger}" == "allowzoom" ]]; then
                dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Enabling …, "
                updateScriptLog "SETUP YOUR MAC DIALOG: Updating the zoom notifications …"
                if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
                    updateScriptLog "SETUP YOUR MAC DIALOG: DEBUG MODE: eval ${jamfBinary} recon ${reconOptions}"
                else
                    sleep 1
                fi               
                dialogUpdateSetupYourMac "listitem: index: $i, status: success, statustext: Enabled"
            fi                       
            ;;



        ###
        # Catch-all
        ###

        * )
            # Output Line Number in `verbose` Debug Mode
            if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi
            updateScriptLog "SETUP YOUR MAC DIALOG: Validate Policy Results Catch-all: ${validation}"
            dialogUpdateSetupYourMac "listitem: index: $i, status: error, statustext: Error"
            ;;

    esac

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Kill a specified process (thanks, @grahampugh!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function killProcess() {
    process="$1"
    if process_pid=$( pgrep -a "${process}" 2>/dev/null ) ; then
        updateScriptLog "Attempting to terminate the '$process' process …"
        updateScriptLog "(Termination message indicates success.)"
        kill "$process_pid" 2> /dev/null
        if pgrep -a "$process" >/dev/null ; then
            updateScriptLog "ERROR: '$process' could not be terminated."
        fi
    else
        updateScriptLog "The '$process' process isn't running."
    fi
}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Completion Action (i.e., Wait, Sleep, Logout, Restart or Shutdown)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function completionAction() {

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then

        # If Debug Mode is enabled, ignore specified `completionActionOption`, display simple dialog box and exit
        runAsUser osascript -e 'display dialog "Setup Your Mac is operating in Debug Mode.\r\r• completionActionOption == '"'${completionActionOption}'"'\r\r" with title "Setup Your Mac: Debug Mode" buttons {"Close"} with icon note'
        exitCode="0"

    else

        shopt -s nocasematch

        case ${completionActionOption} in

            "Shut Down" )
                updateScriptLog "Shut Down sans user interaction"
                killProcess "Self Service"
                # runAsUser osascript -e 'tell app "System Events" to shut down'
                # sleep 5 && runAsUser osascript -e 'tell app "System Events" to shut down' &
                sleep 5 && shutdown -h now &
                ;;

            "Shut Down Attended" )
                updateScriptLog "Shut Down, requiring user-interaction"
                killProcess "Self Service"
                wait
                # runAsUser osascript -e 'tell app "System Events" to shut down'
                # sleep 5 && runAsUser osascript -e 'tell app "System Events" to shut down' &
                sleep 5 && shutdown -h now &
                ;;

            "Shut Down Confirm" )
                updateScriptLog "Shut down, only after macOS time-out or user confirmation"
                runAsUser osascript -e 'tell app "loginwindow" to «event aevtrsdn»'
                ;;

            "Restart" )
                updateScriptLog "Restart sans user interaction"
                killProcess "Self Service"
                # runAsUser osascript -e 'tell app "System Events" to restart'
                # sleep 5 && runAsUser osascript -e 'tell app "System Events" to restart' &
                sleep 5 && shutdown -r now &
                ;;

            "Restart Attended" )
                updateScriptLog "Restart, requiring user-interaction"
                killProcess "Self Service"
                wait
                # runAsUser osascript -e 'tell app "System Events" to restart'
                # sleep 5 && runAsUser osascript -e 'tell app "System Events" to restart' &
                sleep 5 && shutdown -r now &
                ;;

            "Restart Confirm" )
                updateScriptLog "Restart, only after macOS time-out or user confirmation"
                runAsUser osascript -e 'tell app "loginwindow" to «event aevtrrst»'
                ;;

            "Log Out" )
                updateScriptLog "Log out sans user interaction"
                killProcess "Self Service"
                # sleep 5 && runAsUser osascript -e 'tell app "loginwindow" to «event aevtrlgo»'
                # sleep 5 && runAsUser osascript -e 'tell app "loginwindow" to «event aevtrlgo»' &
                sleep 5 && launchctl bootout user/"${loggedInUserID}"
                ;;

            "Log Out Attended" )
                updateScriptLog "Log out sans user interaction"
                killProcess "Self Service"
                wait
                # sleep 5 && runAsUser osascript -e 'tell app "loginwindow" to «event aevtrlgo»'
                # sleep 5 && runAsUser osascript -e 'tell app "loginwindow" to «event aevtrlgo»' &
                sleep 5 && launchctl bootout user/"${loggedInUserID}"
                ;;

            "Log Out Confirm" )
                updateScriptLog "Log out, only after macOS time-out or user confirmation"
                sleep 5 && runAsUser osascript -e 'tell app "System Events" to log out'
                ;;

            "Sleep"* )
                sleepDuration=$( awk '{print $NF}' <<< "${1}" )
                updateScriptLog "Sleeping for ${sleepDuration} seconds …"
                sleep "${sleepDuration}"
                killProcess "Dialog"
                updateScriptLog "Goodnight!"
                ;;

            "Quit" )
                updateScriptLog "Quitting script"
                exitCode="0"
                ;;

            * )
                updateScriptLog "Using the default of 'wait'"
                wait
                ;;

        esac

        shopt -u nocasematch

    fi

    exit "${exitCode}"

}



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Quit Script (thanks, @bartreadon!)
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

function quitScript() {

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    updateScriptLog "QUIT SCRIPT: Exiting …"

    # Stop `caffeinate` process
    updateScriptLog "QUIT SCRIPT: De-caffeinate …"
    killProcess "caffeinate"

    # Toggle `jamf` binary check-in 
    toggleJamfLaunchDaemon

    # Remove overlayicon
    if [[ -e ${overlayicon} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${overlayicon} …"
        rm "${overlayicon}"
    fi
    
    # Remove welcomeCommandFile
    if [[ -e ${welcomeCommandFile} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${welcomeCommandFile} …"
        rm "${welcomeCommandFile}"
    fi

    # Remove setupYourMacCommandFile
    if [[ -e ${setupYourMacCommandFile} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${setupYourMacCommandFile} …"
        rm "${setupYourMacCommandFile}"
    fi

    # Remove failureCommandFile
    if [[ -e ${failureCommandFile} ]]; then
        updateScriptLog "QUIT SCRIPT: Removing ${failureCommandFile} …"
        rm "${failureCommandFile}"
    fi

    # Remove any default dialog file
    if [[ -e /var/tmp/dialog.log ]]; then
        updateScriptLog "QUIT SCRIPT: Removing default dialog file …"
        rm /var/tmp/dialog.log
    fi

    # Check for user clicking "Quit" at Welcome dialog
    if [[ "${welcomeReturnCode}" == "2" ]]; then
        exitCode="1"
        exit "${exitCode}"
    else
        updateScriptLog "QUIT SCRIPT: Executing Completion Action Option: '${completionActionOption}' …"
        completionAction "${completionActionOption}"
    fi

}



####################################################################################################
#
# Program
#
####################################################################################################

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Debug Mode Logging Notification
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
    updateScriptLog "\n\n###\n# ${scriptVersion}\n###\n"
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# If Debug Mode is enabled, replace `blurscreen` with `movable`
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${debugMode}" == "true" ]] || [[ "${debugMode}" == "verbose" ]] ; then
    welcomeJSON=${welcomeJSON//blurscreen/moveable}
    dialogSetupYourMacCMD=${dialogSetupYourMacCMD//blurscreen/moveable}
fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Display Welcome dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ "${welcomeDialog}" == "video" ]]; then

    updateScriptLog "WELCOME DIALOG: Displaying "
    eval "${dialogBinary} --args ${welcomeVideo}"

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "WELCOME DIALOG: # # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi
    symConfiguration="Catch-all (video)"
    policyJSONConfiguration

    eval "${dialogSetupYourMacCMD[*]}" & sleep 0.3
    dialogSetupYourMacProcessID=$!
    until pgrep -q -x "Dialog"; do
        # Output Line Number in `verbose` Debug Mode
        if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi
        updateScriptLog "WELCOME DIALOG: Waiting to display 'Setup Your Mac' dialog; pausing"
        sleep 0.5
    done
    updateScriptLog "WELCOME DIALOG: 'Setup Your Mac' dialog displayed; ensure it's the front-most app"
    runAsUser osascript -e 'tell application "Dialog" to activate'

elif [[ "${welcomeDialog}" == "userInput" ]]; then

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    # Write Welcome JSON to disk
    echo "$welcomeJSON" > "$welcomeCommandFile"

    welcomeResults=$( eval "${dialogApp} --jsonfile ${welcomeCommandFile} --json" )

    if [[ -z "${welcomeResults}" ]]; then
        welcomeReturnCode="2"
    else
        welcomeReturnCode="0"
    fi

    case "${welcomeReturnCode}" in

        0)  # Process exit code 0 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} entered information and clicked Continue"

            ###
            # Extract the various values from the welcomeResults JSON
            ###

            position=$(get_json_value_welcomeDialog "$welcomeResults" "Position")
            userName=$(get_json_value_welcomeDialog "$welcomeResults" "User Name")
            Location=$(get_json_value_welcomeDialog "$welcomeResults" "Location")
            symConfiguration=$(get_json_value_welcomeDialog "$welcomeResults" "Configuration" "selectedValue")
            banner=$(get_json_value_welcomeDialog "$welcomeResults" "Banner" "selectedValue")



            ###
            # Output the various values from the welcomeResults JSON to the log file
            ###

            updateScriptLog "WELCOME DIALOG: • Position: $position"
            updateScriptLog "WELCOME DIALOG: • User Name: $userName"
            updateScriptLog "WELCOME DIALOG: • Location: $Location"
            updateScriptLog "WELCOME DIALOG: • Configuration: $symConfiguration"
            updateScriptLog "WELCOME DIALOG: • Banner: $banner"



            ###
            # Select `policyJSON` based on selected Configuration
            ###

            policyJSONConfiguration



            ###
            # Evaluate Various User Input
            ###

            # Position
            if [[ -n "${position}" ]]; then
                # UNTESTED, UNSUPPORTED "YOYO" EXAMPLE
                reconOptions+="-position \"${position}\" "
            fi

            # User Name
            if [[ -n "${userName}" ]]; then
                # UNTESTED, UNSUPPORTED "YOYO" EXAMPLE
                reconOptions+="-endUsername \"${userName}\" "
            fi

            # Location
            if [[ -n "${Location}" ]]; then
                reconOptions+="-building \"${Location}\" "
            fi

            # Banner
            if [[ -n "${banner}" ]]; then
                # UNTESTED, UNSUPPORTED "YOYO" EXAMPLE
                reconOptions+="-banner \"${banner}\" "
            fi

            # Full Name loggedInUserFullname
             if [[ -n "${loggedInUserFullname}" ]]; then
                # UNTESTED, UNSUPPORTED "YOYO" EXAMPLE
                reconOptions+="-realname \"${loggedInUserFullname}\" "
            fi

            # Output `recon` options to log
            updateScriptLog "WELCOME DIALOG: reconOptions: ${reconOptions}"

            ###
            # Display "Setup Your Mac" dialog (and capture Process ID)
            ###

            eval "${dialogSetupYourMacCMD[*]}" & sleep 0.3
            dialogSetupYourMacProcessID=$!
            until pgrep -q -x "Dialog"; do
                # Output Line Number in `verbose` Debug Mode
                if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi
                updateScriptLog "WELCOME DIALOG: Waiting to display 'Setup Your Mac' dialog; pausing"
                sleep 0.5
            done
            updateScriptLog "WELCOME DIALOG: 'Setup Your Mac' dialog displayed; ensure it's the front-most app"
            runAsUser osascript -e 'tell application "Dialog" to activate'
            ;;

        2)  # Process exit code 2 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} clicked Quit at Welcome dialog"
            completionActionOption="Quit"
            quitScript "1"
            ;;

        3)  # Process exit code 3 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} clicked infobutton"
            osascript -e "set Volume 3"
            afplay /System/Library/Sounds/Glass.aiff
            ;;

        4)  # Process exit code 4 scenario here
            updateScriptLog "WELCOME DIALOG: ${loggedInUser} allowed timer to expire"
            quitScript "1"
            ;;

        *)  # Catch all processing
            updateScriptLog "WELCOME DIALOG: Something else happened; Exit code: ${welcomeReturnCode}"
            quitScript "1"
            ;;

    esac

else

    ###
    # Select "Catch-all" policyJSON 
    ###

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "WELCOME DIALOG: # # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi
    symConfiguration="Catch-all ('Welcome' dialog disabled)"
    policyJSONConfiguration



    ###
    # Display "Setup Your Mac" dialog (and capture Process ID)
    ###

    eval "${dialogSetupYourMacCMD[*]}" & sleep 0.3
    dialogSetupYourMacProcessID=$!
    until pgrep -q -x "Dialog"; do
        # Output Line Number in `verbose` Debug Mode
        if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi
        updateScriptLog "WELCOME DIALOG: Waiting to display 'Setup Your Mac' dialog; pausing"
        sleep 0.5
    done
    updateScriptLog "WELCOME DIALOG: 'Setup Your Mac' dialog displayed; ensure it's the front-most app"
    runAsUser osascript -e 'tell application "Dialog" to activate'

fi



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Iterate through policyJSON to construct the list for swiftDialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Output Line Number in `verbose` Debug Mode
if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

dialog_step_length=$(get_json_value "${policyJSON}" "steps.length")
for (( i=0; i<dialog_step_length; i++ )); do
    listitem=$(get_json_value "${policyJSON}" "steps[$i].listitem")
    list_item_array+=("$listitem")
    icon=$(get_json_value "${policyJSON}" "steps[$i].icon")
    icon_url_array+=("$icon")
done



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Determine the "progress: increment" value based on the number of steps in policyJSON
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Output Line Number in `verbose` Debug Mode
if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

totalProgressSteps=$(get_json_value "${policyJSON}" "steps.length")
progressIncrementValue=$(( 100 / totalProgressSteps ))
updateScriptLog "SETUP YOUR MAC DIALOG: Total Number of Steps: ${totalProgressSteps}"
updateScriptLog "SETUP YOUR MAC DIALOG: Progress Increment Value: ${progressIncrementValue}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# The ${array_name[*]/%/,} expansion will combine all items within the array adding a "," character at the end
# To add a character to the start, use "/#/" instead of the "/%/"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Output Line Number in `verbose` Debug Mode
if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

list_item_string=${list_item_array[*]/%/,}
dialogUpdateSetupYourMac "list: ${list_item_string%?}"
for (( i=0; i<dialog_step_length; i++ )); do
    dialogUpdateSetupYourMac "listitem: index: $i, icon: ${setupYourMacPolicyArrayIconPrefixUrl}${icon_url_array[$i]}, status: pending, statustext: Pending …"
done
dialogUpdateSetupYourMac "list: show"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Set initial progress bar
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Output Line Number in `verbose` Debug Mode
if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

updateScriptLog "SETUP YOUR MAC DIALOG: Initial progress bar"
dialogUpdateSetupYourMac "progress: 1"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Close Welcome dialog
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Output Line Number in `verbose` Debug Mode
if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

dialogUpdateWelcome "quit:"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Update Setup Your Mac's infobox
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Output Line Number in `verbose` Debug Mode
if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi


catchall="#### Model  \n $model \n#### macOS version  \n $macOSproductVersion \n#### Serial number  \n $serialNumber \n#### Current user  \n $loggedInUser"

# When `welcomeDialog` is set to `false` or `video`, set the value of `infoboxConfiguration` to null (thanks for the idea, @Manikandan!)
if [[ "${symConfiguration}" == *"Catch-all"* ]]; then
    infoboxConfiguration="$catchall"
else
    infoboxConfiguration="${symConfiguration}"
fi

infobox=""

if [[ -n ${comment} ]]; then infobox+="**Comment:**  \n$comment  \n\n" ; fi
if [[ -n ${position} ]]; then infobox+="**Business Title | Position:**  \n$position  \n\n" ; fi
if [[ -n ${userName} ]]; then infobox+="**Username:**  \n$userName  \n\n" ; fi
if [[ -n ${Location} ]]; then infobox+="**Location:**  \n$Location  \n\n" ; fi
if [[ -n ${infoboxConfiguration} ]]; then infobox+="\n$infoboxConfiguration  \n\n" ; fi
if [[ -n ${banner} ]]; then infobox+="**Banner:**  \n$banner  \n\n" ; fi

dialogUpdateSetupYourMac "infobox: ${infobox}"



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# This for loop will iterate over each distinct step in the policyJSON
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

for (( i=0; i<dialog_step_length; i++ )); do 

    # Output Line Number in `verbose` Debug Mode
    if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

    # Initialize SECONDS
    SECONDS="0"

    # Creating initial variables
    listitem=$(get_json_value "${policyJSON}" "steps[$i].listitem")
    icon=$(get_json_value "${policyJSON}" "steps[$i].icon")
    progresstext=$(get_json_value "${policyJSON}" "steps[$i].progresstext")
    trigger_list_length=$(get_json_value "${policyJSON}" "steps[$i].trigger_list.length")

    # If there's a value in the variable, update running swiftDialog
    if [[ -n "$listitem" ]]; then
        updateScriptLog "\n\n# # #\n# SETUP YOUR MAC DIALOG: policyJSON > listitem: ${listitem}\n# # #\n"
        dialogUpdateSetupYourMac "listitem: index: $i, status: wait, statustext: Installing …, "
    fi
    if [[ -n "$icon" ]]; then dialogUpdateSetupYourMac "icon: ${setupYourMacPolicyArrayIconPrefixUrl}${icon}"; fi
    if [[ -n "$progresstext" ]]; then dialogUpdateSetupYourMac "progresstext: $progresstext"; fi
    if [[ -n "$trigger_list_length" ]]; then

        for (( j=0; j<trigger_list_length; j++ )); do

            # Setting variables within the trigger_list
            trigger=$(get_json_value "${policyJSON}" "steps[$i].trigger_list[$j].trigger")
            validation=$(get_json_value "${policyJSON}" "steps[$i].trigger_list[$j].validation")
            case ${validation} in
                "Local" | "Remote" )
                    updateScriptLog "SETUP YOUR MAC DIALOG: Skipping Policy Execution due to '${validation}' validation"
                    ;;
                * )
                    confirmPolicyExecution "${trigger}" "${validation}"
                    ;;
            esac

        done

    fi

    validatePolicyResult "${trigger}" "${validation}"

    # Increment the progress bar
    dialogUpdateSetupYourMac "progress: increment ${progressIncrementValue}"

    # Record duration
    updateScriptLog "SETUP YOUR MAC DIALOG: Elapsed Time: $(printf '%dh:%dm:%ds\n' $((SECONDS/3600)) $((SECONDS%3600/60)) $((SECONDS%60)))"

done



# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Complete processing and enable the "Done" button
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# Output Line Number in `verbose` Debug Mode
if [[ "${debugMode}" == "verbose" ]]; then updateScriptLog "# # # SETUP YOUR MAC VERBOSE DEBUG MODE: Line No. ${LINENO} # # #" ; fi

finalise
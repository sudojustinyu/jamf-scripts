#!/bin/sh
####################################################################################################
#
# ABOUT THIS PROGRAM
#
# NAME
#	jamfCyberArkEPMInstallFromDMG -- Install CyberArkEPM version 21.8+ and on from DMG with configuration file
#
# SYNOPSIS
#	sudo jamfCyberArkEPMInstallFromDMG <mountPoint> <computerName> <currentUsername> <dmgName> <SecureToken> <installationKey> [<AdminUsername> <AdminPassword>]

# DESCRIPTION
# Sample script to install CyberArkEPM version 21.8+ with preconfigured set
##############################
#
# 0. Download CyberArkEPMAgentSetupMacOs.zip from EPM server console.
# 1. Unzip CyberArkEPMAgentSetupMacOs.zip to the directory. 
# 2. Rename the directory for something like ./CyberArkEPMAgentSetupMacOs-setX
# 3. Create DMG file by running:  
#
#  hdiutil create -volname CyberarkEPMAgentSetupMacOs -srcfolder ./CyberArkEPMAgentSetupMacOs-setX -ov -format UDZO ./CyberArkEPMAgentSetupMacOs-setX.dmg
#
# 4. Upload CyberArkEPMAgentSetupMacOs-setX.dmg to the Jamf server
# 5. Add  CyberArkEPMAgentSetupMacOs-setX.dmg  to the Policy's pkg payload
#
# Use the attached "jamfCyberArkEPMInstallFromDMG" script in the Jamf policy. 
# 
# You have to provide the below parameters to this script 
# 1. name of DMG file as it is named in Jamf
# 2. SecureToken for the set, if the set is protected
# 3. installationKey for installation
# 4. Optional - Admin User/pass to enable LCD
#
# Exit codes: 
#   0 = Success
#   1 = No DMG file provided
#   2 - No Protection token value provided
#   3 = No Installation Key provided
#   4 - DMG file was not transferred to local disk
#   5 - Other Error
#   6 - LCD integrqation missing Password
#   7 - unhiding _cyberarkepm user failure
#   8 - Other Agent installation failure
####################################################################################################
#set -x

# waiting 10 sec for all tasks completion in JAMF
sleep 10

echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Starting EPM Agent installation Script 1.3"
JAMF_CACHE_LOCATION="/Library/Application Support/JAMF/Waiting Room"

# OPTIONAL PARAMETRES STARTS FROM 4
CYBERARKEPM_INSTALL_DMG="$4"
SECURE_TOKEN="$5" # provide 'none' if there is no protection token
INSTALLATION_KEY="$6"
INSTALL_ADMIN_USER="$7"
INSTALL_ADMIN_PASS="$8"

# Zero the installation agruments
INSTALLATION_ARG=""

# Parameter #4, DMG filename
if [[ "$CYBERARKEPM_INSTALL_DMG" == "" ]] ; then
    echo "`date +"%Y-%m-%d_%H-%M-%S"` ERROR: No DMG filename provided, Exiting..."
    exit 1  
else
    echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Found DMG filename in JAMF value of $CYBERARKEPM_INSTALL_DMG Moving on... "
fi

# Parameter #5, Agent Protection Token
if [[ "$SECURE_TOKEN" == ""  ]] ; then
    echo "`date +"%Y-%m-%d_%H-%M-%S"` ERROR: No protection token provided! Exiting..."
    exit 2
else
    if [[ "$SECURE_TOKEN" == "none" ]] ; then
        echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Protection token value is none, moving on..."
    fi
    echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Protection token value found and added, moving on..."
    INSTALLATION_ARG+=" -token $SECURE_TOKEN "
fi

# Parameter #6, Installation Key
if [[ "$INSTALLATION_KEY" == "" ]] ; then
    echo "`date +"%Y-%m-%d_%H-%M-%S"` ERROR: No Installation Key provided! Exiting..."
    exit 3
else
    echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Found Installation Key, Moving on..."
    INSTALLATION_ARG+=" -installationKey $INSTALLATION_KEY "
fi

# Parameter #7,8 LCD - Admin User/Pass for secure
if [[ "$INSTALL_ADMIN_USER" == "" ]] ; then
    echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: No Admin username provided, Skipping LCD integration Moving on..."
    INSTALLATION_ARG+=" -withoutPwdRotation "
else
    if [[ "$INSTALL_ADMIN_PASS" == "" ]] ; then
        echo "`date +"%Y-%m-%d_%H-%M-%S"` ERROR: Admin username provided for LCD but no password, Exiting..."
        exit 6
    else
        INSTALLATION_ARG+=" -adminUser $INSTALL_ADMIN_USER -adminPassword $INSTALL_ADMIN_PASS"
        echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Found Admin Username and Password, will try  for LCD integration..."
    fi
fi

echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Checking for DMG file existance on the local disk at $JAMF_CACHE_LOCATION/$CYBERARKEPM_INSTALL_DMG"

if [[ ! -f "$JAMF_CACHE_LOCATION/$CYBERARKEPM_INSTALL_DMG" ]]; then
    echo "`date +"%Y-%m-%d_%H-%M-%S"` ERROR: The file $JAMF_CACHE_LOCATION/$CYBERARKEPM_INSTALL_DMG was not found!, Exiting..."
    exit 4
else    
    echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: The file $JAMF_CACHE_LOCATION/$CYBERARKEPM_INSTALL_DMG was found, Moving on..."
fi

CYBERARKEPM_INSTALL_TMP=$(mktemp -d -t ci-XXXXXXXXXX)
rm -fr $CYBERARKEPM_INSTALL_TMP
mkdir -p $CYBERARKEPM_INSTALL_TMP
echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Created temp directory $CYBERARKEPM_INSTALL_TMP"

sudo /usr/bin/hdiutil attach -nobrowse -mountpoint $CYBERARKEPM_INSTALL_TMP/dmg "$JAMF_CACHE_LOCATION/$CYBERARKEPM_INSTALL_DMG"


echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Extracting DMG packages"
ditto -xk $CYBERARKEPM_INSTALL_TMP/dmg/Install\ CyberArk\ EPM.app.zip $CYBERARKEPM_INSTALL_TMP
cp -a $CYBERARKEPM_INSTALL_TMP/dmg/CyberArkEPMAgentSetupMacos.config $CYBERARKEPM_INSTALL_TMP/CyberArkEPMAgentSetupMacos.config
xattr -d $CYBERARKEPM_INSTALL_TMP/Install\ CyberArk\ EPM.app

echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Unmounting DMG file from $CYBERARKEPM_INSTALL_TMP/dmg" 
sudo /usr/bin/hdiutil detach $CYBERARKEPM_INSTALL_TMP/dmg

echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Cleanup directory $CYBERARKEPM_INSTALL_TMP from unnessesary files" 
rm -f "$JAMF_CACHE_LOCATION/$CYBERARKEPM_INSTALL_DMG"
rm -f "$JAMF_CACHE_LOCATION/$CYBERARKEPM_INSTALL_DMG.cache.xml"

echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Starting EPM Agent installation package..."

$CYBERARKEPM_INSTALL_TMP/Install\ CyberArk\ EPM.app/Contents/MacOS/CyberArkEPMInstaller -configuration "$CYBERARKEPM_INSTALL_TMP/CyberArkEPMAgentSetupMacos.config" $INSTALLATION_ARG
if [ $? -eq 0 ] ; then
    echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Successful Agent installation completed"
else    
    echo "`date +"%Y-%m-%d_%H-%M-%S"` ERROR: Failed to install CyberArk EPM Agent, Exiting..."
    exit 8
fi

if [[ "$INSTALL_ADMIN_USER" == "" ]] ; then
    echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: No Admin username provided, Skipping unhiding epm user. Moving on..."
else
    echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Attempting to unhide epm user..."
    dscl . create /Users/_cyberarkepm IsHidden 0
    if [ $? -eq 0 ] ; then
      echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Successful epm user unhiding"
    else
        echo "`date +"%Y-%m-%d_%H-%M-%S"` ERROR: Failed to unhide the epm user"
 #       exit 7
    fi
fi

sleep 5
echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Enabling CyberArk EPM Finder Extension"
pluginkit -e use -i com.cyberark.CyberArkEPMFinderSyncExtension
if [ $? -eq 0 ] ; then
    echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Successful enabling CyberArk EPM Finder Extension"
else    
    echo "`date +"%Y-%m-%d_%H-%M-%S"` ERROR: Failed Enabling CyberArk EPM Finder Extension"
fi

echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: Final cleanup of directory $CYBERARKEPM_INSTALL_TMP" 
rm -rf $CYBERARKEPM_INSTALL_TMP

echo "`date +"%Y-%m-%d_%H-%M-%S"` INFO: CyberArk EPM installation completed, Goodbye..."

exit 0

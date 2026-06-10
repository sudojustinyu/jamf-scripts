#!/bin/bash
# General SCS installer for all companys

#unzip the zscaler zip file 
sudo unzip -o /Library/Application\ Support/JAMF/Waiting\ Room/Zscaler-osx-3.9.0.113-installer.app.zip -d /Users/Shared/

#run the zscaler install command with arguments
#https://help.zscaler.com/z-app/customizing-zscaler-app-install-options-macos
sudo sh /Users/Shared/Zscaler-osx-3.9.0.113-installer.app/Contents/MacOS/installbuilder.sh --cloudName zscalertwo --mode unattended --unattendedmodeui none

#cleanup, delete the unzipped file
rm -rf /Users/Shared/Zscaler-osx-3.9.0.113-installer.app

#cleanup, delete previous installer if it exists
if ls /Applications/Zscaler/RevertZcc/Zscaler* 1> /dev/null 2>&1; then
	echo "Removing Previous Version Installer"
    rm -rf /Applications/Zscaler/RevertZcc/Zscaler*
else
	echo "Previous Version Installer Not Found"
fi
#!/bin/bash
# Cameron Stone
# Chun Jiang 
# JY
# last updated 2022113

#unzip the zscaler zip file 
sudo unzip -o /Library/Application\ Support/JAMF/Waiting\ Room/Zscaler-osx-3.4.1.14-installer.app.zip -d /Users/Shared/

#run the zscaler install command with arguments
#https://help.zscaler.com/z-app/customizing-zscaler-app-install-options-macos
sudo sh /Users/Shared/Zscaler-osx-3.4.1.14-installer.app/Contents/MacOS/installbuilder.sh --cloudName zscalertwo --userDomain saks.com --mode unattended --unattendedmodeui none

#cleanup, delete the unzipped file
rm -rf /Users/Shared/Zscaler-osx-3.4.1.14-installer.app
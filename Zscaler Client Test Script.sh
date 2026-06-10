#!/bin/bash
# Cameron Stone
# Chun Jiang 
# Justin Yu
# last updated 20220421

#unzip the zscaler zip file 
sudo unzip -o /Library/Application\ Support/JAMF/Waiting\ Room/Zscaler-osx-3.6.1.19-installer.app.zip -d /Users/Shared/

#run the zscaler install command with arguments
#https://help.zscaler.com/z-app/customizing-zscaler-app-install-options-macos
sudo sh /Users/Shared/Zscaler-osx-3.6.1.19-installer.app/Contents/MacOS/installbuilder.sh --cloudName zscalertwo --userDomain saks.com --strictEnforcement 1 --mode unattended --unattendedmodeui none --policyToken 353437373A343A39623965353165352D343632622D343037322D626537342D343839363565633964656630

#cleanup, delete the unzipped file
rm -rf /Users/Shared/Zscaler-osx-3.6.1.19-installer.app
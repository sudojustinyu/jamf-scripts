#!/bin/bash

##########################################################################
#               Install Application from DMG in Jamf Waiting ROOM
# Created By: Christopher Glover
# Date: 03/26/2018
# 
# Disclaimer:
# These scripts come without warranty of any kind. Use them at your own risk. 
# I assume no liability for the accuracy, correctness, completeness, or usefulness of any information 
# provided by this site nor for any sort of damages using these scripts may cause. 
##########################################################################


# Changes directory to '/library/Application Support/JAMF/Waiting Room/' this is where JSS storred cached files.
cd /library/Application Support/JAMF/Waiting Room/

#Mounts Downloaded DMG within the Jamf Waiting room
hdiutil attach -nobrowse WrikeDesktopApp.v3.3.14.dmg

#Detatches the DMG 
hdiutil detach /Applications/Wrike

#Changes directory to '/library/Application Support/JAMF/Waiting Room/' this is where JSS storred cached files
cd /library/Application Support/JAMF/Waiting Room/

echo "cleaning up"
#Cleans Up the dmg so it doesnt take up space on machine
rm WrikeDesktopApp.v3.3.14.dmg

#cleans out the XML 
rm WrikeDesktopApp.v3.3.14.dmg

exit 0
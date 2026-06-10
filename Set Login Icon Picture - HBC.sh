#!/bin/sh

#Get current user
user=`ls -l /dev/console | cut -d " " -f 4`

# Check for hbclogo.png
echo Checking for Check for hbclogo.png.....
if [ -f /Users/Shared/hbclogo.png ]; then

echo found hbclogo.png changing user icon

dscl . delete /Users/$user JPEGPhoto
dscl . delete /Users/$user Picture
dscl . create /Users/$user Picture "/Users/Shared/hbclogo.png"
else
echo hbclogo.png not found.
fi
exit 0
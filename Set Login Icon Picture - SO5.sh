#!/bin/sh

#Get current user
user=`ls -l /dev/console | cut -d " " -f 4`

# Check for so5logo.png
echo Checking for Check for so5logo.png.....
if [ -f /Users/Shared/so5logo.png ]; then

echo found so5logo.png changing user icon

dscl . delete /Users/$user JPEGPhoto
dscl . delete /Users/$user Picture
dscl . create /Users/$user Picture "/Users/Shared/so5logo.png"
else
echo so5logo.png not found.
fi
exit 0
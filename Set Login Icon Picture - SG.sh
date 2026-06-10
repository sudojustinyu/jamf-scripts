#!/bin/sh

#Get current user
user=`ls -l /dev/console | cut -d " " -f 4`

# Check for hbclogo.png
echo Checking for Check for saks_global_square.png.....
if [ -f /Users/Shared/saks_global_square.png ]; then

echo found saks_global_square.png changing user icon

dscl . delete /Users/$user JPEGPhoto
dscl . delete /Users/$user Picture
dscl . create /Users/$user Picture "/Users/Shared/saks_global_square.png"
else
echo saks_global_square.png not found.
fi
exit 0
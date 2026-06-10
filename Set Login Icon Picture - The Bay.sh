#!/bin/sh

#Get current user
user=`ls -l /dev/console | cut -d " " -f 4`

# Check for sakslogo.jpg
echo Checking for Check for saks.jpg.....
if [ -f /Users/Shared/thebay.png ]; then

echo found saks.jpg changing user icon

dscl . delete /Users/$user JPEGPhoto
dscl . delete /Users/$user Picture
dscl . create /Users/$user Picture "/Users/Shared/thebay.png"
else
echo thebay.png not found.
fi
exit 0
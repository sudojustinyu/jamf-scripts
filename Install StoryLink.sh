#!/bin/sh
currentUser=$(who | awk '/console/{print $1}')
echo $currentUser
mv /Users/Shared/mac-install /Users/$currentUser/Downloads/mac-install
mv /Users/Shared/storyLink-22.433.zxp /Users/$currentUser/Downloads/storyLink-22.433.zxp
cd Users/$currentUser/Downloads/
chmod +x  mac-install
./mac-install
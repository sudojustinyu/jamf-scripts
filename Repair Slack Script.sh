#!/bin/bash
loggedInUser=$( echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )

RemoveSlack ()
{
killall Slack
rm -rf /Applications/Slack.app 
rm -rf /Users/$loggedInUser/Library/Application\ Support/Slack 
rm -rf /Users/$loggedInUser/Library/Caches/com.tinyspeck.slackmacgap
rm -rf /Users/$loggedInUser/Library/Caches/com.tinyspeck.slackmacgap.ShipIt
rm -rf /Users/$loggedInUser/Library/HTTPStorages/com.tinyspeck.slackmacgap
rm -rf /Users/$loggedInUser/Library/HTTPStorages/com.tinyspeck.slackmacgap.binarycookies 
rm -rf /Users/$loggedInUser/Library/Preferences/ByHost/com.tinyspeck.slackmacgap.ShipIt.F19956EC-905E-5407-A924-538CAF7B0338.plist
rm -rf /Users/$loggedInUser/Library/Preferences/com.tinyspeck.slackmacgap.plist
rm -rf /Users/$loggedInUser/Library/Saved\ Application\ State/com.tinyspeck.slackmacgap.savedState
ReinstallSlack
}
ReinstallSlack ()
{
/usr/local/jamf/bin/jamf policy -id 70 -verbose
AddSlackToDock
}
AddSlackToDock ()
{
currentUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ { print $3 }' )
uid=$(id -u "${currentUser}")
runAsUser() {
	if [[ "${currentUser}" != "loginwindow" ]]; then
		launchctl asuser "$uid" sudo -u "${currentUser}" "$@" >> /var/log/ripeda_dock.log
	else
		echo "no user logged in"
		exit 1
	fi
}
__dock_item() {
    printf '%s%s%s%s%s' \
           '<dict><key>tile-data</key><dict><key>file-data</key><dict>' \
           '<key>_CFURLString</key><string>' \
           "$1" \
           '</string><key>_CFURLStringType</key><integer>0</integer>' \
           '</dict></dict></dict>'
}
runAsUser defaults write com.apple.dock \
				persistent-apps -array-add \
							"$(__dock_item /Applications/Slack.app)"
killall -KILL Dock
open "/Applications/Slack.app"  
}
RemoveSlack
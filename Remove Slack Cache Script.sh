#!/bin/bash
loggedInUser=$( echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
set -x

RemoveSlackCache ()
{
process="Slack"
if ! pgrep -f "$process"; then
	echo "Slack is closed already will proceed with removing the cache"
else
	echo "Slack is open will proceed with closing the app"
	killall Slack
fi
rm -rf /Users/$loggedInUser/Library/Caches/com.tinyspeck.slackmacgap
rm -rf /Users/$loggedInUser/Library/Caches/com.tinyspeck.slackmacgap.ShipIt
UpdateSlack
}
UpdateSlack ()
{
/usr/local/jamf/bin/jamf policy -id 126 -verbose
open "/Applications/Slack.app"
}
RemoveSlackCache
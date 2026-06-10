#!/bin/bash

# Slack For HBC

slackOn=$(pgrep '[S]lack')

# The kill
pkill Slack*

# gets current logged in user
consoleuser=$(ls -l /dev/console | cut -d " " -f4)

APP_NAME="Slack.app"
APP_PATH="/Applications/$APP_NAME"
APP_VERSION_KEY="CFBundleShortVersionString"


DOWNLOAD_URL="https://slack.com/ssb/download-osx"
finalDownloadUrl=$(curl "$DOWNLOAD_URL" -s -L -I -o /dev/null -w '%{url_effective}')
dmgName=$(printf "%s" "${finalDownloadUrl[@]}" | sed 's@.*/@@')
slackDmgPath="/tmp/$dmgName"

latestver=$(curl -sL 'https://slack.com/release-notes/mac/rss' | grep -o "Slack-[0-9]*\.[0-9]*\.[0-9]*"  | cut -c 7-14 | head -n 1)


# Get the version number of the currently-installed Slack, if any.
if [ -e "$APP_PATH" ]; then
	currentinstalledver=`defaults read "$APP_PATH/Contents/Info.plist" "$APP_VERSION_KEY"`
	echo "Current installed version is: $currentinstalledver"
	if [ ${latestver} = ${currentinstalledver} ]; then
		echo "Latest Version Already Installed. Exiting"
		exit 0
	fi
	else
		currentinstalledver="none"
		echo "Slack is not installed"
fi

# Compare the two versions, if they are different or Zoom is not present then download and install the new version.
if [ "${currentinstalledver}" != "${latestver}" ]; then

	# Remove the existing Application
	rm -rf "$APP_PATH"

	#downloads latest version of Slack
	curl -L -o "$slackDmgPath" "$finalDownloadUrl"

	# mount the .dmg
	hdiutil attach -nobrowse $slackDmgPath

	# Copy the update app into applications folder
	sudo cp -R /Volumes/Slack*/Slack.app /Applications

	# unmount and eject dmg
	mountName=$(diskutil list | grep Slack | awk '{ print $3 }')
    hdiutil detach $(df | grep "${mountName}" | awk '{print $1}') -quiet


	# clean up /tmp download
	rm -rf "$slackDmgPath"

	# Slack permissions are really dumb
	chown -R $consoleuser:admin /Applications/Slack.app && chmod -R 755 /Applications/Slack.app


	# Double check to see if the new version got updated
	newlyinstalledver=$(defaults read "$APP_PATH/Contents/Info.plist" "$APP_VERSION_KEY")
	echo "Newly Installed Version is: $newlyinstalledver"
		if [ "${latestver}" = "${newlyinstalledver}" ]; then
		echo "`date`: SUCCESS: Slack has been updated to version ${newlyinstalledver}" 
		else
 		echo "`date`: ERROR: Slack update unsuccessful, version remains at ${currentinstalledver}." 
 	exit 1
  	fi

	# If Slack is up to date already, just log it and exit.
	else
	echo "`date`: Slack is already up to date, running ${currentinstalledver}." 
fi      

# Slack will relaunch if it was previously running
if [ "$slackOn" == "" ] ; then
	exit 0
	else
	su - "${consoleuser}" -c 'open -a /Applications/Slack.app'
fi

exit 0

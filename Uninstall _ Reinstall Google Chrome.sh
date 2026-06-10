#!/bin/bash
#set-x
loggedInUser=$( echo "show State:/Users/ConsoleUser" | scutil | awk '/Name :/ && ! /loginwindow/ { print $3 }' )
# StandardChromeInstallLocation
ChromeLocation="/Applications/Google Chrome.app"
# Current Chrome Download URL
fileURL="https://dl.google.com/chrome/mac/universal/stable/CHFA/googlechrome.dmg"
# Specify name of the local disk image flash player will be downloaded to
chrome_dmg="/tmp/chrome.dmg"


UninstallChrome ()
{
process="Google Chrome"
if ! pgrep -f "$process"; then
	echo "Google Chrome is closed already will proceed with uninstalling the app"
else
	echo "Google Chrome is open will proceed with closing the app"
    ## We need to use killall with the -9 flag otherwise the entire FireFox process group won't quit
	## And at some point Chrome changed the binary name to lowercasse so we include both processes.
	killall -9 "$process"
    
fi

sleep 1

if [ -e "$ChromeLocation" ]
   then
   echo "Uninstalling Chrome"
   /bin/rm -rf "$ChromeLocation"
   rm -rf /Users/$loggedInUser/Library/Application\ Support/CrashReporter/Google\ Chrome_F19956EC-905E-5407-A924-538CAF7B0338.plist 
   rm -rf /Users/$loggedInUser/Library/Preferences/com.google.Chrome.plist 
   rm -rf /Users/$loggedInUser/Library/Saved\ Application\ State/com.google.Chrome.savedState
   rm -rf /Users/$loggedInUser/Library/Application\ Support/Google/Chrome
   rm -rf /Users/$loggedInUser/Library/Google
   rm -rf /private/var/db/receipts/com.google.Chrome.bom
   rm -rf /private/var/db/receipts/com.google.Chrome.plist
   ReinstallChrome
   else
   echo "No current installation of Chrome found in the default location."
   ReinstallChrome
fi
}
ReinstallChrome ()
{

  echo "Reinstalling Chrome"
  # Download the latest Chrome software disk image	
  # We use Curl with the --progress-bar option so it only displays information about its download progress
  # When then have to send curl output to stdout because it defaults to stderr
	
   /usr/bin/curl --progress-bar --output "$chrome_dmg" "$fileURL" 2>&1 



    # Specify a /tmp/chrome.XXXX mountpoint for the disk image.
    # Using mktemp allows the chrome mount point to get created with 4 random characters after
    # the . This unqique name (which is temporary) provides a greater degree of certainity that
    # the same name and as a result data won't be used. The -d option indicates that this is a 
    # directory since this is needed for a mountpoint.		
 
    TMPMOUNT=`/usr/bin/mktemp -d /tmp/chrome.XXXX`

    # Mount the latest Chrome disk image to /tmp/chrome.XXXX mountpoint
 
    /usr/bin/hdiutil attach "$chrome_dmg" -mountpoint "$TMPMOUNT" -nobrowse -noverify -noautoopen

    # Progress message with bar at 50% to let users know installation is continuing
    # At this point we are copying chrome
    
    # Copy Chrome from the the disk image, set the appropriate permissions, and remove extend attributes
    # User the R option to make sure sub files are copied. Use p to preserve the finder icon. Can
    # prob switch this to rsync

    /bin/cp -Rp  $TMPMOUNT/Google\ Chrome.app /Applications

    sleep .5

    /usr/sbin/chown -R root:admin "$ChromeLocation"
    /bin/chmod -R 775 "$ChromeLocation"
    /usr/bin/xattr -d com.apple.quarantine "$ChromeLocation"
    

    # Unmount the Chrome Player disk image from /tmp/flashplayer.XXXX
 
    /usr/bin/hdiutil detach "$TMPMOUNT"
 
    # Remove the /tmp/chrome.XXXX mountpoint
 
    /bin/rm -rf "$TMPMOUNT"

    # Remove the downloaded disk image

    /bin/rm -rf "$chrome_dmg"
    open "$ChromeLocation"
    AddChromeDock
}
AddChromeDock ()
{
echo "Adding Chrome Back To Dock"
uid=$(id -u "${loggedInUser}")
runAsUser() {
	if [[ "${loggedInUser}" != "loginwindow" ]]; then
		launchctl asuser "$uid" sudo -u "${loggedInUser}" "$@" >> /var/log/ripeda_dock.log
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
							"$(__dock_item /Applications/Google\ Chrome.app)"
killall -KILL Dock
}
UninstallChrome
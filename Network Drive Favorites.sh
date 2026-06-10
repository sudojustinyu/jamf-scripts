#!/bin/bash
USERNAME=$( echo "show State:/Users/ConsoleUser" | /usr/sbin/scutil | /usr/bin/awk '/Name :/ && ! /loginwindow/ { print $3 }' )
plist=$HOME'/Library/Preferences/com.apple.sidebarlists.plist'
rm -rf /Users/$USERNAME/Library/Preferences/com.apple.sidebarlists.plist

#Contents of plist file com.apple.sidebarlists.plist
cat > /Users/$USERNAME/Library/Preferences/com.apple.sidebarlists.plist << 'ENDSCRIPT'

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>favoriteservers</key>
	<dict>
		<key>Controller</key>
		<string>CustomListItems</string>
		<key>CustomListItems</key>
		<array>
			<dict>
				<key>Name</key>
				<string>smb://public-volume.intranet.saksroot.saksinc.com/</string>
				<key>URL</key>
				<string>smb://public-volume.intranet.saksroot.saksinc.com/</string>
			</dict>
			<dict>
				<key>Name</key>
				<string>smb://t49-vol3.intranet.saksroot.saksinc.com/</string>
				<key>URL</key>
				<string>smb://t49-vol3.intranet.saksroot.saksinc.com/</string>
			</dict>
			<dict>
				<key>Name</key>
				<string>smb://t49-vol4.intranet.saksroot.saksinc.com/</string>
				<key>URL</key>
				<string>smb://t49-vol4.intranet.saksroot.saksinc.com/</string>
			</dict>
			<dict>
				<key>Name</key>
				<string>smb://t49-vol5.intranet.saksroot.saksinc.com/</string>
				<key>URL</key>
				<string>smb://t49-vol5.intranet.saksroot.saksinc.com/</string>
			</dict>
		</array>
	</dict>
</dict>
</plist>

ENDSCRIPT

chmod +x /Users/$USERNAME/Library/Preferences/com.apple.sidebarlists.plist
killall Finder
killall cfprefsd
killall sharedfilelistd
defaults read ${plist} favoriteservers > /dev/null
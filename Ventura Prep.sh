#!/bin/zsh

TempUtilitiesPath=/usr/local/ventura-upgrade

BaseString=com.saks.syseng-venturaupgrade
ScriptName=${BaseString}-installer.zsh
ScriptPath=${TempUtilitiesPath}/${ScriptName}
UnInstallerScriptName=${BaseString}-uninstaller.zsh
UnInstallerScriptPath=${TempUtilitiesPath}/${UnInstallerScriptName}

#Using /Library/LaunchDaemons for the LaunchDaemon
LaunchDaemonName=${BaseString}.plist
LaunchDaemonPath="/Library/LaunchDaemons"/${LaunchDaemonName}

# The following will create a script that triggers the policy to start.
echo "Creating ${ScriptPath}."
(
cat <<ENDOFINSTALLERSCRIPT
#!/bin/zsh
until [ -f /var/log/jamf.log ]
do
	echo "Waiting for jamf log to appear"
	sleep 1
done
until (sudo jamf checkJSSConnection -retry 1 !=)
do
	echo "Waiting for jamf connection."
	sleep 1
done
/usr/local/jamf/bin/jamf policy -event cleanup-ventura
exit 0

ENDOFINSTALLERSCRIPT
) > "${ScriptPath}"

echo "Setting permissions for ${ScriptPath}."
chmod 755 "${ScriptPath}"
chown root:wheel "${ScriptPath}"

#-----------

# The following will create the LaunchDaemon file that starts the script that waits for Jamf Pro
# then runs the jamf policy -event command.

echo "Creating ${LaunchDaemonPath}."
(
cat <<ENDOFLAUNCHDAEMON
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>${BaseString}</string>
	<key>RunAtLoad</key>
	<true/>
	<key>UserName</key>
	<string>root</string>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/zsh</string>
		<string>${ScriptPath}</string>
	</array>
	<key>StandardErrorPath</key>
	<string>/var/tmp/${ScriptName}.err</string>
	<key>StandardOutPath</key>
	<string>/var/tmp/${ScriptName}.out</string>
</dict>
</plist>

ENDOFLAUNCHDAEMON
)  > "${LaunchDaemonPath}"

echo "Setting permissions for ${LaunchDaemonPath}."
chmod 644 "${LaunchDaemonPath}"
chown root:wheel "${LaunchDaemonPath}"

echo "Loading ${LaunchDaemonName}."
launchctl load "${LaunchDaemonPath}"

#-----------

# The following will create the script file to uninstall the LaunchDaemon and installer script.
echo "Creating ${UnInstallerScriptPath}."
(
cat <<ENDOFUNINSTALLERSCRIPT
#!/bin/zsh
# This is meant to be called by a Jamf Pro policy via trigger

rm ${ScriptPath}

#Note that if you unload the LaunchDaemon this will immediately kill the depNotify.sh script
#Just remove the underlying plist file, and the LaunchDaemon will not run after next reboot/login.

rm ${LaunchDaemonPath}
rm ${UnInstallerScriptPath}
rmdir ${TempUtilitiesPath}

exit 0
exit 1

ENDOFUNINSTALLERSCRIPT
) > "${UnInstallerScriptPath}"

echo "Setting permissions for ${UnInstallerScriptPath}."
chmod 644 "${UnInstallerScriptPath}"
chown root:wheel "${UnInstallerScriptPath}"

exit 0		## Success
exit 1		## Failure
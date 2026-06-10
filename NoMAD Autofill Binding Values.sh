#!/bin/sh

## Get the logged in username
loggedInUser=$(stat -f%Su /dev/console)

## Run command as user
sudo -u $loggedInUser /usr/bin/defaults write com.trusourcelabs.NoMAD ADDomain -string hbc.com
sudo -u $loggedInUser /usr/bin/defaults write com.trusourcelabs.NoMAD KerberosRealm  -string HBC.COM
sudo -u $loggedInUser /usr/bin/defaults write com.trusourcelabs.NoMAD LocalPasswordSync -string 1
sudo -u $loggedInUser /usr/bin/defaults write com.trusourcelabs.NoMAD DontShowWelcomeDefaultOn -boolean true
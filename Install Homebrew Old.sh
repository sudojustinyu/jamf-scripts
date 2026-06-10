#!/bin/sh
#Justin Yu
#Zainul Somrow
#Chun Jiang
#20220125
#This script is used to install homebrew without using root permission, it is a necessary workaround for saks developers to install homebrew in this way.
#requires git to be preinstalled
#copy and paste from cyberark https://cyberark-customers.force.com/s/article/How-to-install-HomeBrew-on-Mac-with-EPM-as-a-User-context
#
# install Brew Script
cd $HOME
 
echo "Home Address=$HOME ;"
 
gitVersionLog="$(git version)"
echo "Git Version= $gitVersionLog ;"
git clone https://github.com/Homebrew/brew.git
echo "git Clone status=Success;"
 
echo 'export PATH=$HOME/brew/bin:$PATH' > .bash_profile
echo "Create .bash_profile status=Success;"
 
echo 'export PATH=$HOME/brew/bin:$PATH' > .zshrc
echo "Create .zshrc status=Success;"
 
chown -R $USER brew .bash_profile .zshrc
echo "chown status=Success;"
#
#display window for end user
osascript -e 'tell app "System Events" to display dialog "HomeBrew Installation complete!"'
#kill the jamf self service, work around for bug where the application is installed but self service keep displaying the status is still loading
pkill -x Self\ Service
#kill any running terminal session, users need to open new session for brew command to work, so this will force them to do so
Killall Terminal
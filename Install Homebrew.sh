#!/bin/sh

#Justin Yu

#Zainul Somrow

#Chun Jiang

#20220915

#This script is used to install homebrew without using root permission, it is a necessary workaround for saks developers to install homebrew in this way.

#requires git to be preinstalled

#Fix the original CyberArk one with Seth Woodworth recommendation #

# install Brew Script

cd $HOME 

echo "Home Address=$HOME ;"

gitVersionLog="$(git version)"

echo "Git Version= $gitVersionLog ;"

git clone https://github.com/Homebrew/brew.git homebrew

echo "git Clone status=Success;"

eval "$(homebrew/bin/brew shellenv)"

brew update --force --quiet

chmod -R go-w "$(brew --prefix)/share/zsh"

#display window for end user

osascript -e 'tell app "System Events" to display dialog "HomeBrew Installation complete!"'

#kill the jamf self service, work around for bug where the application is installed but self service keep displaying the status is still loading

pkill -x Self\ Service

#kill any running terminal session, users need to open new session for brew command to work, so this will force them to do so

Killall Terminal
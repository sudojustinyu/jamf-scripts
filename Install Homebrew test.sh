#!/bin/bash

currentuser=$(/bin/ls -la /dev/console | /usr/bin/cut -d ' ' -f 4)

su -l $currentuser -c "$cd $HOME"

su -l $currentuser -c "echo "Home Address=$HOME ;"

su -l $currentuser -c "gitVersionLog="$(git version)"

su -l $currentuser -c "echo "Git Version= $gitVersionLog ;"

su -l $currentuser -c "git clone https://github.com/Homebrew/brew.git homebrew"

su -l $currentuser -c "echo "git Clone status=Success;"

su -l $currentuser -c "eval "$(homebrew/bin/brew shellenv)"

su -l $currentuser -c "brew update --force --quiet"

su -l $currentuser -c "chmod -R go-w "$(brew --prefix)/share/zsh"

#display window for end user

sudo jamf displayMessage -message 'HomeBrew Installation complete!'

#kill the jamf self service, work around for bug where the application is installed but self service keep displaying the status is still loading

pkill -x Self\ Service

#kill any running terminal session, users need to open new session for brew command to work, so this will force them to do so

Killall Terminal
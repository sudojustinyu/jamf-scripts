#!/bin/bash

currentuser=$(/bin/ls -la /dev/console | /usr/bin/cut -d ' ' -f 4)

# main code starts here

#unlink md5sha1sum
su -l $currentuser -c  "brew unlink md5sha1sum"

#Download asdf
su -l $currentuser -c  "git clone https://github.com/asdf-vm/asdf.git ~/.asdf"

#unlink coreutils
su -l $currentuser -c "brew unlink coreutils"

#relink md5sha1sum
su -l $currentuser -c "brew link md5sha1sum"

#Enable asdf
su -l $currentuser -c "plugins=(asdf)"

#Plugin Dependencies
su -l $currentuser -c  "brew install gpg gawk"

#Install the Python Plugin
su -l $currentuser -c "asdf plugin add python"

#Install latest version
su -l $currentuser -c "asdf install python latest"





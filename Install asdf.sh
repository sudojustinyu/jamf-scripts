#!/bin/bash

currentuser=$(/bin/ls -la /dev/console | /usr/bin/cut -d ' ' -f 4)

# main code starts here

#unlink md5sha1sum
su -l $currentuser -c  "brew unlink md5sha1sum"

#Download asdf
su -l $currentuser -c  "brew install asdf"

#unlink coreutils
su -l $currentuser -c "brew unlink coreutils"

#relink md5sha1sum
su -l $currentuser -c "brew link md5sha1sum"




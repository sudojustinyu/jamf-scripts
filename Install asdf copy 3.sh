#!/bin/bash

currentuser=$(/bin/ls -la /dev/console | /usr/bin/cut -d ' ' -f 4)

# main code starts here

#unlink md5sha1sum
su -l $currentuser -c  "brew unlink md5sha1sum"

#Download asdf
su -l $currentuser -c  "git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.10.2"

#Add asdf to zsh profile
su -l $currentuser -c ". $HOME/.asdf/asdf.sh"

# append completions to fpath
su -l $currentuser -c "fpath=(${ASDF_DIR}/completions $fpath)"

# initialise completions with ZSH's compinit
su -l $currentuser -c "autoload -Uz compinit && compinit"

#Plugin Dependencies
su -l $currentuser -c "brew install gpg gawk"

#Add Python
su -l $currentuser -c "asdf plugin-add python"

#unlink coreutils
su -l $currentuser -c "brew unlink coreutils"

#relink md5sha1sum
su -l $currentuser -c "brew link md5sha1sum"




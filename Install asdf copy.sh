#!/bin/bash

currentuser=$(/bin/ls -la /dev/console | /usr/bin/cut -d ' ' -f 4)
# Set the prefix based on the machine type
if [[ "$UNAME_MACHINE" == "arm64" ]]; then
    # M1/arm64 machines
    HOMEBREW_PREFIX="/opt/homebrew"
fi

#Install asdf

su -l $currentuser -c "echo -e "\n. $($HOMEBREW_PREFIX asdf)/libexec/asdf.sh" >> ${ZDOTDIR:-~}/.zshrc"





#!/bin/sh

## Developed by Graham Gilbert
## https://grahamgilbert.com/blog/2020/11/13/installing-rosetta-2-on-apple-silicon-macs/

arch=$(/usr/bin/arch)

if [ "$arch" == "arm64" ]
then
  if [ ! -f "/Library/Apple/System/Library/LaunchDaemons/com.apple.oahd.plist" ]
  then
    echo "Installing Rosetta 2."
    /usr/sbin/softwareupdate --install-rosetta --agree-to-license
  else
    echo "Rosetta 2 already installed"
  fi
else
  echo "Not an Apple Silicon Mac. Skipping Installation."
fi

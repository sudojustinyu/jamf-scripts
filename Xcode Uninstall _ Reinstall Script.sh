#!/bin/sh
if [ -d "/Library/Developer/CommandLineTools" ]; then
echo "Xcode command line tools found let's remove it"
sudo rm -rf /Library/Developer/CommandLineTools
else
echo "Not found"
fi
xcode-select --install

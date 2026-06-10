#!/bin/zsh

if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
	echo "Dialog not found, installing..."
	sudo jamf policy -id 360
    if [ ! -e "/Library/Application Support/Dialog/Dialog.app" ]; then
    	echo "Install was successful"	
    else 
    	echo "Install Failed exiting out"
    	exit 6
    fi	
else
	echo "swiftDialog already exists"
fi

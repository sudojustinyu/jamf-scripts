#!/bin/bash
# Remove Jumpcloud Account
# This script will remove the Jumpcloud account I will specify the account name in Parameter 4 of the policy

accountName=$4

if [ ! -z "$accountName" ] && [[ `/usr/bin/dscl . list /Users | grep "$accountName"` == "$accountName" ]]; then
    sudo dscl . delete /Users/"$accountName"
	
fi
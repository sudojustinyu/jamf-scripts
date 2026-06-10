#!/bin/bash

# Script To Remove Local Admin Accounts
#
#
# Created by Samuel Alvarez on 02/09/22
#
sudo dscl . delete /Users/test
sudo rm -rf /Users/test
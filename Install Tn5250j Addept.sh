#!/bin/sh
currentUser=$(who | awk '/console/{print $1}')
echo $currentUser
mv /Users/Shared/tn5250j.app /Applications

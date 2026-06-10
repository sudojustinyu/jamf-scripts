#!/bin/sh
# Version 1.0

# Written by: Joe Brown | Saks

# This script is designed to remove the built in apps by using
# the apps array.


###############################################################
# Apps Variable to Modify
###############################################################
  APPS_ARRAY=(
    GarageBand.app
    iMovie.app
    Keynote.app
    Numbers.app
    Pages.app
  )

# Loop to run removal of apps in array
  for apps in "${APPS_ARRAY[@]}"; do
    # Remove app
		find /Applications -name apps -type d -exec rm -r {} +
  done

exit 0
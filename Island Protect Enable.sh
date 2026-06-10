#!/bin/bash

services=("io.island.service" "io.island.updater")

for service in "${services[@]}"; do
    if /bin/launchctl list | grep -q "$service"; then
        echo "Service $service is already running."
    else
        echo "Service $service is not running. Starting it..."
        /bin/launchctl load /Library/LaunchDaemons/"$service".plist
    fi
done
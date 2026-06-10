#!/bin/bash
curl -Lo /tmp/Zoom.pkg https://zoom.us/client/latest/ZoomInstallerIT.pkg;
installer -pkg /tmp/Zoom.pkg -target /Applications;
rm /tmp/Zoom.pkg
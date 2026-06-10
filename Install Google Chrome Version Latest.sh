#!/bin/bash
curl -Lo /tmp/Google\ Chrome.dmg https://dl.google.com/chrome/mac/stable/GGRO/googlechrome.dmg;
hdiutil attach /tmp/Google\ Chrome.dmg;
ditto -rsrc /Volumes/Google\ Chrome/Google\ Chrome.app /Applications/Google\ Chrome.app;
hdiutil detach /Volumes/Google\ Chrome;
rm /tmp/Google\ Chrome.dmg;
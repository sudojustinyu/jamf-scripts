#!/bin/sh
killall Box
fileproviderctl domain remove -A com.box.desktop.boxfileprovider; defaults delete com.box.desktop; rm -rf ~/Library/Application\ Support/Box/Box
/Library/Application\ Support/Box/uninstall_box_drive

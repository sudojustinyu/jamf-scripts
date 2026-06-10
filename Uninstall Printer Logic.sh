#!/bin/sh


# Check if the specified application is installed ...
if [ -d "/opt/PrinterInstallerClient/service_interface/PrinterInstallerClient.app" ] ; then

    echo "/opt/PrinterInstallerClient/service_interface/PrinterInstallerClient.app located; proceeding ..."

    echo "Removing /opt/PrinterInstallerClient/service_interface/PrinterInstallerClient.app ..."

    sudo /opt/PrinterInstallerClient/bin/./uninstall.sh

    echo "Removed /opt/PrinterInstallerClient/service_interface/PrinterInstallerClient.app."

    exit 0

else

    echo "/opt/PrinterInstallerClient/service_interface/PrinterInstallerClient.app NOT found; nothing to remove."

    exit 0

fi

exit 0
#!/bin/bash
# Function to install NVM
install_nvm() {
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
    # Source NVM scripts to use NVM in the current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    echo "NVM installed."
}
# Check if NVM is installed by looking for the nvm command
if ! command -v nvm &> /dev/null; then
    install_nvm
else
    echo "NVM is already installed."
fi
# Using osascript to prompt the user for the Node version. Note the careful escaping of quotes.
NODE_VERSION=$(osascript <<EOF
Tell application "System Events"
    display dialog "Enter Node version to install (or type 'node' for the latest version):" default answer ""
end tell
text returned of result
EOF
)
# Check if a version was specified and install it using NVM
if [[ ! -z "$NODE_VERSION" ]]; then
    nvm install "$NODE_VERSION"
    echo "Node $NODE_VERSION installed successfully."
else
    echo "No version specified. Exiting..."
fi
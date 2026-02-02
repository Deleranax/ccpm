#!/bin/bash

# Go to repository root
cd $(git rev-parse --show-toplevel)

DESTINATION=~/.local/share/ccemux/computer/0/

# Delete and recreate the destination directory
rm -rf "${DESTINATION}"* "${DESTINATION}".[!.]* "${DESTINATION}"..?*

# Copy the installer
cp ./installer-craftos.lua "$DESTINATION"

#!/bin/bash

# Go to repository root
cd $(git rev-parse --show-toplevel)

DESTINATION=~/.var/app/cc.craftos_pc.CraftOS-PC/data/craftos-pc/computer/0

# Delete and recreate the destination directory
rm -rf "${DESTINATION}"* "${DESTINATION}".[!.]* "${DESTINATION}"..?*

# Copy all files from the packages source to the destination directory
for i; do
    cp -a "./packages/${i}/source/." "$DESTINATION"
done

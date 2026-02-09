#!/bin/bash

# Go to repository root
cd $(git rev-parse --show-toplevel)

DESTINATION=~/.var/app/cc.craftos_pc.CraftOS-PC/data/craftos-pc/computer/0

# Delete and recreate the destination directory
rm -rf "${DESTINATION}"* "${DESTINATION}".[!.]* "${DESTINATION}"..?*

# Copy all files from each package source to the destination directory
for package in $(ls -d ./packages/*/); do
    cp -a "${package}source/." "$DESTINATION"
done

# Copy the installer
cp ./installer-craftos.lua "$DESTINATION"

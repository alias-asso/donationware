#!/bin/bash

set -euo pipefail

version=44
fedora_release="https://download.fedoraproject.org/pub/fedora/linux/releases/$version"
path_base="/tmp/fedora-donationware-$version"

cd "$(dirname "$0")"

# Create the ISO layout and bundle the boot files needed to start the installer.
mkdir -p "$path_base/boot/grub"

# Copy the GRUB menu and make the ISO boot the bundled kernel by default.
cp grub.cfg $path_base/boot/grub/grub.cfg

# Copy the kernel and initrd used by the installer.
wget "$fedora_release/Server/x86_64/os/images/pxeboot/vmlinuz" -O "$path_base/vmlinuz"
wget "$fedora_release/Server/x86_64/os/images/pxeboot/initrd.img" -O "$path_base/initrd.img"

# Generate the ISO.
grub2-mkrescue -o Fedora-Donationware-$version.iso "$path_base"

# Cleanup the ISO layout.
rm -rf "$path_base"
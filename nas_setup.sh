#!/usr/bin/env ash

# Install packages required to turn the router into a NAS
# NOTE: if you get any errors (e.g. no more room on /overlay), try rebooting the router

opkg update;
opkg install kmod-usb-storage kmod-fs-ext4 kmod-fs-ntfs ntfs-3g ntfs-3g-utils block-mount fdisk;

# Install USB3 drivers if needed:
opkg install kmod-usb3;

# Install Letsencrypt acme tool (if needed)
opkg install acme;

# Install Samba v4 file server
opkg install luci-app-samba4;

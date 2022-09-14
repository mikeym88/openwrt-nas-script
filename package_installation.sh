#!/usr/bin/env ash

# Install packages required to turn the router into a NAS
# NOTE: if you get any errors (e.g. no more room on /overlay), try rebooting the router

opkg update;

# Install drivers and filesystem support
opkg install kmod-usb-storage kmod-fs-ext4 kmod-fs-ntfs kmod-usb-storage-uas kmod-fs-exfat kmod-fs-f2fs kmod-fs-vfat;

# Install filesystem utilities
opkg install ntfs-3g ntfs-3g-utils block-mount e2fsprogs f2fs-tools dosfstools libblkid;

# Install general disk utilities
opkg install fdisk mount-utils usbutils lsblk;

# Install other useful utilities
opkg install shadow-useradd;

# Install USB3 drivers if needed:
opkg install kmod-usb3;

# Install Samba v4 file server
opkg install luci-app-samba4;
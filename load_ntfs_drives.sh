#!/usr/bin/env ash

# This is a script that loads NTFS drives in OpenWRT
# Paste or call this script in the Local Startup section
# NOTES:
#   - must have the lsblk and jq packages installed
#   - must specify user (see "uid=1001,gid=1001" below)

NTFS_DRIVES=$(lsblk -f -J | jq -r '.blockdevices | .[] | select(.children) | .children[] | select(.fstype=="ntfs") | (.name + "," + .label)');

for i in $NTFS_DRIVES; do
    drive=$(echo $i | cut -d ',' -f 1);
    label=$(echo $i | cut -d ',' -f 2);
    if [[ -z $label ]]; then
        label=$drive;
    fi
    mnt_point=/mnt/$label;
    if [[ ! -e $mnt_point ]]; then
        mkdir -p $mnt_point;
    fi
    ntfs-3g /dev/$drive $mnt_point -o rw,noatime,uid=1001,gid=1001;
done
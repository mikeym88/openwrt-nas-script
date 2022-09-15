#!/usr/bin/env ash

# Do not include the above shebang (#!...) when you paste this script in the
# Local Startup section (under System -> Startup -> Local Startup tab)


# This is a script that loads NTFS drives in OpenWRT
# Paste or call this script in the Local Startup section
# NOTES:
#   - must have the lsblk and jq packages installed
#   - must specify user (see "uid=1001,gid=1001" below)

NTFS_DRIVES=$(lsblk -f -J | jq -r '.blockdevices | .[] | select(.children) | .children[] | select(.fstype=="ntfs") | (.name + "," + .label)');

for i in $NTFS_DRIVES; do
    drive=$(echo $i | cut -d ',' -f 1);
    label=$(echo $i | cut -d ',' -f 2);
    
    # Create mount point; if drive has a label, use that as the mnt name
    mount_name='';
    if [[ -z $label ]]; then
        mount_name=$drive;
    fi
    mnt_point=/mnt/$mount_name;
    
    # Handle case where multiple drives have the same label/mount point
    i=1;
    while [[ -e $mnt_point ]]; do
        mnt_point=/mnt/$mount_name_$i;
        i=i+1;
    done

    # Create the mount directory
    if [[ ! -e $mnt_point ]]; then
        mkdir -p $mnt_point;
    fi

    # Finally, mount the drive
    ntfs-3g /dev/$drive $mnt_point -o rw,noatime,uid=1001,gid=1001;
done
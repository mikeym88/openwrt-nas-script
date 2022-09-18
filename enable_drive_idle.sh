#!/usr/bin/env ash

# A rudimentary script that enables HD Idle spindown of USB drives that are currently plugged in.
# NOTE: This script will delete all the current HD idle rules (whether they're enabled or not)
#       and add new ones.

delete_all_hd_idle_rules () {
  num_idle_entries=$(uci show hd-idle | sed -r 's/hd-idle.@hd-idle\[(\d)\].*/\1/g' | sort -n | tail -1);
  echo "Deleting $num_idle_entries config entries."
  while uci get hd-idle.@hd-idle[-1] &> /dev/null ; do
    uci delete hd-idle.@hd-idle[-1];
  done
}

add_all_drive_rules() {
    drive_names=$(lsblk -f -J | jq -r '.blockdevices | .[] | select(.name | startswith("sd")) | .name');
    for name in $drive_names; do
        echo "Adding HD Idle rule for $name";
        uci add hd-idle hd-idle;
        uci set hd-idle.@hd-idle[-1].enabled='1';
        uci set hd-idle.@hd-idle[-1].disk="$name";
        uci set hd-idle.@hd-idle[-1].idle_time_interval='5';
        uci set hd-idle.@hd-idle[-1].idle_time_unit='minutes';
    done
}

update_hd_idle_rules () {
  echo "Applying Changes";
  delete_all_hd_idle_rules;
  add_all_drive_rules;
  echo "Applying Changes";
  uci commit hd-idle;
  service hd-idle reload;
  num_idle_entries=$(uci show hd-idle | sed -r 's/hd-idle.@hd-idle\[(\d)\].*/\1/g' | sort -n | tail -1);
  echo "Added $num_idle_entries config entries."
}

update_hd_idle_rules;
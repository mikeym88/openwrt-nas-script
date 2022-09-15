#!/usr/bin/env ash

# This script sets up the router:
#   - Set hostname and timezone
#   - Change IP address from 192.168.1. to something else
#       - Either set it to static or change to DHCP
#   - Disable firewall, dnsmasq, dhcp (because they're handled by the main router)
#   - Delete the WAN interface and assign the port to the LAN interface


initial_setup () {
  # Change password
  passwd;

  NEW_HOSTNAME="NASROUTER";

  # Validate parameter
  if [[ ! -z "$1" && "$1" =~ ^[a-zA-Z0-9]\([a-zA-Z0-9\-]*[a-zA-Z0-9]+\)?$ ]]; then
    NEW_HOSTNAME=$1;
    echo "Setting hostname to $NEW_HOSTNAME";
  else
    echo "Hostname passed is not passed or not valid; setting hostname to $NEW_HOSTNAME.";
  fi
  # Set Hostname and timezone
  uci set system.@system[0].hostname="$NEW_HOSTNAME"
  uci set system.@system[0].description="File server, CRON server, etc."
  uci commit system
  /etc/init.d/system restart

  # These services do not need to run
  for i in dnsmasq odhcpd; do
    if /etc/init.d/"$i" enabled; then
      /etc/init.d/"$i" disable
      /etc/init.d/"$i" stop
    fi
  done

  # Set IP Address, Gateway, and disable DHCP
  # uci set network.lan.ipaddr="192.168.1.2"
  # uci set network.lan.gateway="192.168.1.1"
  uci set network.lan.proto='dhcp'
  uci set dhcp.lan.ignore='1'

  # Delete WAN interface and add port to the LAN interface
  uci delete network.wan
  uci delete network.wan6
  uci delete network.lan.ipaddr
  uci delete network.lan.netmask
  uci add_list network.@device[0].ports='wan'

  # Delete firewall zones and rules because WAN doesn't exist anymore
  while uci get firewall.@zone[-1] &> /dev/null ; do
      uci delete firewall.@zone[-1];
  done

  while uci get firewall.@rule[-1] &> /dev/null ; do
      uci delete firewall.@rule[-1];
  done

  # commit all changes
  uci commit

  reboot
}

create_user () {
  # Create non-privileged user
  USERNAME=$1;

  if [[ ! -z "$1" ]]; then
    echo "Argument is: $1";
  else
    echo "Argument is not populated";
  fi

  # Add user
  useradd -U -s /bin/ash $USERNAME -c "User-created account";
  if [[ $? -ne 0 ]]; then
    echo "Username not properly formatted: $USERNAME";
    exit 1;
  fi

  # Create password for user
  passwd $USERNAME;

  # Create user home directory
  mkdir -p /home/"$1";
  chown $USERNAME /home/$USERNAME;
}

create_samba_user () {
  # https://openwrt.org/docs/guide-user/services/nas/samba_configuration#adding_samba_user_s
  USERNAME="samba";
  GROUP="nas"

  # Add group if it does not exist
  if !(grep -q -E "^$GROUP:" /etc/group); then 
    groupadd $GROUP;
  else
    echo "Samba group, $GROUP, already exists.";
  fi
  
  # Add user if it does not exist
  if !(grep -q -E "^$USERNAME:" /etc/passwd); then 
    useradd -g $GROUP $USERNAME -c "Account for Samba shares";
  else
    echo "Samba user, $USERNAME, already exists.";
  fi

  # Create password for user
  passwd $USERNAME;
}

"$@"
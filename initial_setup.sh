#!/usr/bin/env ash

# This script sets up the router:
#   - Set hostname and timezone
#   - Change IP address from 192.168.1. to something else
#       - Either set it to static or change to DHCP
#   - Disable firewall, dnsmasq, dhcp (because they're handled by the main router)
#   - Delete the WAN interface and assign the port to the LAN interface


SAMBA_USERNAME="samba";
SAMBA_GROUP="nas";


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
  uci delete network.wan;
  uci delete network.wan6;
  uci delete network.lan.ipaddr;
  uci delete network.lan.netmask;
  
  lan_ports=$(uci get network.@device[0].ports);
  if [[ "$lan_ports" =~ ".* wan" ]]; then
    echo "WAN port already assigned to LAN interface.";
  else
    echo "Assign WAN port to LAN interface."
    uci add_list network.@device[0].ports='wan'
  fi

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

create_samba_group () {
  # Add group if it does not exist
  if !(grep -q -E "^$SAMBA_GROUP:" /etc/group); then 
    echo "Creating $SAMBA_GROUP group";
    groupadd $SAMBA_GROUP;
  else
    echo "Samba group, $SAMBA_GROUP, already exists.";
  fi
}

create_samba_user () {
  # https://openwrt.org/docs/guide-user/services/nas/samba_configuration#adding_samba_user_s
  # Add samba user if it does not exist
  create_samba_group

  if !(grep -q -E "^$SAMBA_USERNAME:" /etc/passwd); then 
    echo "Creating samba user";
    useradd -g $SAMBA_GROUP $SAMBA_USERNAME -c "Account for Samba shares";
  else
    echo "Samba user, $SAMBA_USERNAME, already exists.";
  fi
  # Create password for user
  echo "Create password for 'samba' OpenWrt user account"
  passwd $SAMBA_USERNAME;

  echo "Create password for 'samba' Samba4 user account"
  smbpasswd -a $SAMBA_USERNAME;
}

configure_samba () {
  echo "Configuring Samba server";
  create_samba_user;
  if (grep -q -e "\tusername map =" /etc/samba/smb.conf.template); then 
    echo "Setting 'username map' already exists in /etc/samba/smb.conf.template";
  else 
    echo "Adding 'username map' setting in /etc/samba/smb.conf.template";
    sed -i -r "/################ Filesystem/s/^/\tusername map = \/etc\/samba\/username.map\n\n/" /etc/samba/smb.conf.template
  fi
  
  echo "Creating /etc/samba/username.map";
  touch /etc/samba/username.map;

  echo "Updating server descriptiong";
  uci set samba4.@samba[0].description="$HOSTNAME NAS server";
  uci commit samba4;
  service samba4 restart;
}

create_user () {
  create_samba_group

  # Create non-privileged user
  USERNAME="$1";

  if [[ ! -z "$1" ]]; then
    echo "Creating account with user is: $USERNAME, and adding to group $SAMBA_GROUP";
  else
    echo "Argument is not populated";
  fi

  # Add user
  if !(grep -q -E "^$USERNAME:" /etc/passwd); then 
    useradd -U -m -c "User-created account" -s /bin/ash -G $SAMBA_GROUP $USERNAME;
    
    if [[ $? -ne 0 ]]; then
      echo "Username not properly formatted: $USERNAME";
      exit 1;
    else
      echo "Account created.";
    fi
  else
    echo "Account already exists.";
  fi

  # Create password for user
  echo "Create password for $USERNAME (for shell access, web access, etc.):";
  passwd $USERNAME;

  # Create Samba password
  echo "Create Samba4 password for $USERNAME";
  smbpasswd -a $USERNAME;
}

"$@"
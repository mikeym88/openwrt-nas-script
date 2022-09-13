#!/usr/bin/env ash

# This script sets up the router:
#   - Set hostname and timezone
#   - Change IP address from 192.168.1. to something else
#       - Either set it to static or change to DHCP
#   - Disable firewall, dnsmasq, dhcp (because they're handled by the main router)
#   - Delete the WAN interface and assign the port to the LAN interface

# Change password
passwd

# Set Hostname and timezone
uci set system.@system[0].hostname='WRT1900AC'
uci set system.@system[0].zonename='America/Vancouver'
uci commit system
/etc/init.d/system restart

# These services do not need to run
for i in firewall dnsmasq odhcpd; do
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


# commit all changes

uci commit

# remove the firewall config

mv /etc/config/firewall /etc/config/firewall.old

reboot
# OpenWRT NAS Script

Scripts to convert a router into a NAS using OpenWRT. These scripts assume you already have OpenWRT installed and it's uninitialized (i.e. it's been fully reset).

## Setup

### Transferring the scripts

To transfer files to the router, run the following command from a terminal (by default, the router IP address is 192.168.1.1):

```
scp *.sh root@192.168.1.1:~
```

### Running the intial setup script

Next, run the initial file  by running the following commands:

```
ssh root@192.168.1.1
./initial_setup.sh
```

The script will prompt you to set the intial password. By default, the scripts will change the router from a Static IP address to a DHCP address.

### Running the NAS setup script

TODO

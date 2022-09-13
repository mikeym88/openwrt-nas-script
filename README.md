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

You'll need to install the relevant packages to enable the router to be a file server. 

#### Connecting using the new IP address

To do so, you will need to first SSH into the router. The IP address will no longer be same, since it was changed in the previous section. If you specific a static IP address in the previous section (e.g. 192.168.1.2), then `192.168.1.x` (below) will be `192.168.1.2`. If you specified DHCP, then you will need to find the IP address by logging into the main router (if you have access to it) and looking up the new IP address.

```
ssh root@192.168.1.x
```

#### Installing Relevant Packages

Next, you will need to install the relevant packages, including:

* Kernel filesystem packages for the filesystems like NTFS, ext4, etc.
* Kernel drivers for USB storage, USB3.0, etc.
* Samba4 Server + LUCI interface
* Utilities like `fdisk`, `block-mount`, etc.
* Other relevant packages (I've included `acme`, `python3` since those are packages that I use often)

To insntall them, run the following script:

```
./package_installation.sh
```

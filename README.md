# OpenWRT NAS Script

Do you have an older router that is lying around collecting dust? Well you can repurpose it! I was inspired to create these script after watching a few of [OneMarcFifty](https://www.youtube.com/c/OneMarcFifty)'s videos, particularly:

* [Building a managed switch with OpenWrt on old Wifi Router](https://www.youtube.com/watch?v=yCV-08tSwe8)
* [cheap DIY NAS from old Router with OpenWrt and Samba for your home network](https://www.youtube.com/watch?v=vTxfgstBIlE)

The scripts in this repo will help you to convert a router into a NAS using OpenWRT. These scripts assume you already have OpenWRT installed and it's uninitialized (i.e. it's been fully reset).

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
./initial_setup.sh initial_setup
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
* Samba4 Server + LuCI interface
* Utilities like `fdisk`, `block-mount`, etc.
* Other relevant packages (I've included `acme`, `python3` since those are packages that I use often)

To install them, run the following script:

```
./package_installation.sh
```

### Configuring and Mounting the External Drives

* [OpenWRT NAS Guide](https://openwrt.org/docs/guide-user/services/nas/start)
 * This guide provides additional information and instructions, inlcuding how to set up SCSI devides and set more granular firewall rules.
* [OpenWRT Filesystems](https://openwrt.org/docs/guide-user/storage/filesystems-and-partitions)

### Packages required

To mount the drives, make sure you have the following packages installed:

* `block-mount`: provides an interface for mounting the drives
* `kmod-usb-storage`: provides the kernel modules to be able to detect USB storage devices
    * `kmod-usb3` for USB 3.0 drivers (if your router has USB3.0 ports).
    * `kmod-usb-storage-uas`
* Kernel modules and utilities for the filesystems you want to use; examples:
   * `kmod-fs-ext4` for ext4 filesystems.
   * `kmod-fs-ntfs` and `ntfs-3g` for NTFS filesystems.

### Mounting NTFS Drives

TODO

### Mounting Other Drives

TODO

## Custom OpenWRT Build

To convert a router to purely a home server or file server (i.e. not using as an actual router), your best bet is to create a custom OpenWRT image for it. The reason being is that router firmware is flashed to a read-only section. Meaning: if you want to uninstall a built-in package (e.g. the DHCP server), you won't be able to recover the space it took up. Hence why you want to build a custom image: to recover the space lost to unwanted/unneeded packages.

For more information:
* [Which packages can I safely remove to save space?](https://openwrt.org/faq/which_packages_can_i_safely_remove_to_save_space)
* [Build image for devices with only 4MB flash](https://openwrt.org/faq/build_image_for_devices_with_only_4mb_flash)
* [Saving firmware space and RAM](https://openwrt.org/docs/guide-user/additional-software/saving_space)

### Building the custom image

To build a custom OpenWRT image, the easiest way would be to use the [Image Builder](https://openwrt.org/docs/guide-user/additional-software/imagebuilder). 

1. Download the **Image Builder archive** from the same place where you would download your router's firmware.
    * For example: I have a Linksys WRT1900AC v1 router. The OpenWRT 22.03 downloads for the router are listed here: <https://downloads.openwrt.org/releases/22.03.0/targets/mvebu/cortexa9/>
        * The image I would normally download is [linksys_wrt1900ac-v1-squashfs-factory.img](https://downloads.openwrt.org/releases/22.03.0/targets/mvebu/cortexa9/openwrt-22.03.0-mvebu-cortexa9-linksys_wrt1900ac-v1-squashfs-factory.img)
        * The image builder is [openwrt-imagebuilder-22.03.0-mvebu-cortexa9.Linux-x86_64.tar.xz](https://downloads.openwrt.org/releases/22.03.0/targets/mvebu/cortexa9/openwrt-imagebuilder-22.03.0-mvebu-cortexa9.Linux-x86_64.tar.xz)
2. Unzip the archive and switch to the directory:
   ```
   tar -J -x -f openwrt-imagebuilder-*.tar.xz
   cd openwrt-imagebuilder-*/
   ```
3. Create the custom image with the router profile and the packages you want to add or remove. Run `make info` to get the profiles - this is where I got `linksys_wrt1900ac-v1` seen in the example below:
   ```
   make image \
      PROFILE="linksys_wrt1900ac-v1" \
      FILES="files" \
      DISABLED_SERVICES="dnsmasq odhcpd" \
      PACKAGES="kmod-usb-storage kmod-fs-ext4 kmod-fs-ntfs kmod-usb-storage-uas kmod-fs-exfat kmod-fs-f2fs kmod-fs-vfat \
                ntfs-3g ntfs-3g-utils block-mount e2fsprogs f2fs-tools dosfstools libblkid \
                fdisk gdisk mount-utils usbutils lsblk blkid jq \
                sudo shadow-useradd shadow-groupadd shadow-groups shadow-usermod \
                luci luci-app-samba4 luci-app-hd-idle \
                kmod-usb3 acme python3 git libupm-nrf24l01-python3 \
                -wpad-mesh-wolfssl -odhcpd -ppp -ppp-mod-pppoe -odhcpd-ipv6only"
   ```
   **NOTEs**: 
      * The second-last line are additional optional packages. The `kmod-usb3` package is needed if your router supports USB3.0. The others are ones that I personally use frequently.
      * The files parameter will add the configuration files under `<buildroot>/files/etc`, e.g.:
         * `<buildroot>/files/etc` has the configs for SSH settings, custom SSL certificates, users/groups, etc.; and 
         * `<buildroot>/files/etc/config` has the configs for network, Firewall, switch, etc.

## Troubleshooting

TODO

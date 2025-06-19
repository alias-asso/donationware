# ALIAS - PXE Server

## Description
This repository contains all the necessary files to deploy a PXE server on a Fedora based system. It's designed to be used in a local network to boot other machines via network. The PXE server will provide the necessary files to boot the client machine and install Fedora 42 via network. 

## Files explanation
### Main
- `install.sh` : Installation script to deploy the PXE server;

### DHCP
- `dhcpd.conf` : DHCP configuration file ;
- `dhcp_on_commit.sh` : Script to update AIMS when a client machine is connected to the network ;

### PXE
- `grub.cfg` : GRUB configuration file ;
- `default` : SYSLINUX configuration file (not used) ;

### Fedora installation
- `ks.cfg` : Kickstart file for Fedora 42 installation ;

## DHCP
The configuration file is located at `dhcpd.conf`. The configuration is set to provide the necessary files to boot the client machine and to inform AIMS of the installation. This allow an easy recensement.

The DHCP server has been set to be used in a local network (with no router)/no DHCP server. To change the settings, check the official documentation.

## PXE
### GRUB (BIOS/Legacy and UEFI boot)
The PXE server uses GRUB for both BIOS/Legacy and UEFI boot. The configuration file is located at `grub.cfg`.

#### Menu options
- Fedora 42 (Auto-install)
- Reboot
- Shutdown
- UEFI Firmware Settings

### SYSLINUX (BIOS/Legacy boot)
While SYSLINUX is not used for booting, `install.sh` still deploy all the needed files for. If you want to use it, just change the DHCP configuration file according to.

### How to boot
1. Connect the client machine to the same network as the PXE server (using an Ethernet cable) ;
2. Turn on the client machine and press the key to boot using another method ;
3. Select the network boot option.

If the client machine can't boot over network or if you don't want to allow it, you can use a Ventoy USB key and use network boot via iPXE.

## Fedora installation
As said, Fedora 42 Workstation will be installed on the computer. The installer is named `Anaconda` and shares the same specs than Red Hat OS. The Kickstart file (containing all the necessary information for the installation) is located at `ks.cfg`.

After booting via PXE, the installation should takes around 30min.

### What's happening during the installation?
### Before the installation
We recommend to reset the BIOS settings of the client machine before the installation. Make sure to set the best settings, regarding disk performances, etc.

### After booting over the network
AIMS should display a new line with the MAC address of the computer. Click on the related row and set the number of the computer. After that, put the number on the computer (using a post-it, for example).

#### During the installation
As said previously, the installation attempts to install a Workstation-like edition of Fedora 42, including GNOME Desktop and related packages. AIMS will be updated when the installation starts (after fetching all the files) and when it's completed.

Note that if an error occures during the installation, the installer will display an error message, and an indication will be displayed on AIMS.

### Post-installation
After the installation, the client machine will be shutdown. Before anything, disconnect the Ethernet cable to avoid any issue with AIMS. You can now boot it normally and check if Fedora 42 is correctly installed.

### How-to prepare the `install.sh` script for a new Fedora version?
1. Change the version number into the `install.sh` script (first line) ;
2. On a new virtual machine, deploy the PXE server using `install.sh` script ;
3. Use another virtual machine to boot over the network and install Fedora 42 ;
4. Check if everything is working properly (AIMS, installation, etc.)

## Deploy the PXE server
1. Clone this repository on the server ;
2. Run the `install.sh` script as root

## AIMS (Automated Installation Monitoring System)
As you may noticed, there is a directory named aims at `/aims`. AIMS is not mendated but is used to monitor the installations of the client machines. It's a simple web application made in NodeJS that shows the status of the installations.

AIMS is automatically installed when you run the `install.sh` script. You can access it by opening your browser and going to `http://localhost` on the PXE server. 

AIMS stores:
- The MAC address of the client machine ;
- The number of the client machine ;
- The name of the client machine (Brand + Model) ;
- The processor name of the client machine ;
- The amount of RAM of the client machine ;
- The amount of RAM slots of the client machine ;
- The amount of available RAM slots of the client machine ;
- The amount of storage of the client machine ;
- The GPU of the client machine ;
- The current step of the installation (Preparation, Installation, Done) ;
- The date of the last step update. 

All the informations (except the number of the client machine) are automatically fetched by the client machine during the installation. The number of the client machine is set by the user on AIMS.
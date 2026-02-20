# ALIAS - PXE Server

## Description
This repository contains all the necessary files to deploy the PXE server on a Fedora based system. It's designed to be used in a local network to boot other machines via network. The PXE server will provide the necessary files to boot the client machine and install Fedora 43 via network. 

## PXE server
### Stack
| Component | Description |
|-----------|-------------|
| dhcp-server  | DHCP server to provide IP addresses and PXE boot information |
| Apache   | HTTP server to serve the Fedora installation files and act as a proxy |
| GRUB     | Bootloader to load the Fedora installer |

### Files
|Path|Description|
|----|-----------|
|`install.sh`|Installation script to deploy the PXE server ;
|`pxe/dhcpd.conf`|DHCP configuration file.
|`pxe/grub.cfg`|GRUB configuration file.
|`pxe/fedora/ks.cfg`|Kickstart file for Fedora installation.
|`pxe/fedora/.treeinfo`|File used for Anaconda (Fedora installer) to know the structure of the installation source.
|`pxe/fedora/anaconda_report.sh`|Script to report the installation progress to the Reporter service`.

### DHCP
The configuration is set to provide the necessary files to boot the client machine and to inform the reporter of the IP attribution. This allow an easy recensement.

The DHCP server has been set to be used in a local network with no router/DHCP server. To change the settings, check the official documentation.

### Installation
You just need to run the `install.sh` script as root. It will install all the necessary packages, configure them, and start the services.

Note: In order to use the reporter correctly, you need to connect the computer to a local network and to the internet (using two different interfaces).

#### Menu options
| Menu option | Description |
|-------------|-------------|
| Fedora 43 (Auto-install) | Fully automated installation of Fedora 43 (fetch files through HTTP) |
| Fedora 43 (Auto-install) - Fallback | Same as before but fetch files through TFTP |
| Reboot | Reboot the client machine |
| Shutdown | Shutdown the client machine |
| UEFI Firmware Settings | Access UEFI firmware settings (if supported) |
The fallback is automatically used if the first option fails. It can be useful if the client machine has issues with HTTP.

### How to boot
1. Connect the client machine to the local network of the PXE server (using an Ethernet cable) ;
2. Boot into network (IPv4).

If the client machine can't boot over network or if you don't want to allow it, you can use a Ventoy USB key and use network boot via iPXE ISO.

### Fedora installation
As said, Fedora 43 Workstation will be installed on the computer. The installer is named `Anaconda` and shares the same specs than Red Hat OSes. The Kickstart file contains all the necessary information for the installation.

After booting via PXE, the installation should takes around 30min.

#### What's happening during the installation of a computer?
Globally, when an installation is started, no action is required, except if an error occures. However, some actions are recommended before, during and after the installation.

##### Before the installation
We recommend to reset the BIOS settings of the client machine before the installation. Make sure to set the best settings, regarding disk performances, etc.

#### Post-installation
After the installation, the client machine will be shutdown. You can now boot it normally and check if Fedora 43 is correctly installed.

### How-to prepare the `install.sh` script for a new Fedora version?
1. Change the version number into the `install.sh` script (first line) and everywhere it's used (like here, in config files, ...) ;
2. On a new virtual machine, deploy the PXE server using `install.sh` script ;
3. Use another virtual machine to boot over the network and install the new Fedora version ;
4. Check if everything is working properly (reporter, installation, etc.)

## Reporter
The `/reporter` directory contains a NodeJS application. It's designed to send the data received from the DHCP server and Anaconda installer to Google Sheet and keep track of the installation process/computer specs.
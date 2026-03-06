# ALIAS - PXE Server

This repository contains all the necessary files to deploy the PXE server on a Fedora based system. It's designed to be used in a local network to boot other machines via network. The PXE server will provide the necessary files to boot the client machine and install Fedora 43 via network. 

# PXE server
## Stack
| Component | Description |
|-----------|-------------|
| dhcp-server  | DHCP server to provide IP addresses and PXE boot information |
| Apache   | HTTP server to serve the Fedora installation files |
| GRUB     | Bootloader to load the Fedora installer |

## Files
|Path|Description|
|----|-----------|
|`install.sh`|Installation script to deploy the PXE server
|`pxe/dhcpd.conf`|DHCP configuration file
|`pxe/grub.cfg`|GRUB configuration file
|`pxe/fedora/ks.cfg`|Kickstart file for Fedora installation
|`pxe/fedora/.treeinfo`|File used for Anaconda (Fedora installer) to know the structure of the installation source
|`pxe/fedora/anaconda_report.sh`|Script to report the installation progress to the Reporter service`

## DHCP
The configuration is set to provide the necessary GRUB files to boot the client machine and to inform the reporter of the IP attribution. This allow an easy recensement.

The DHCP server has been set to be used in a local network with no router/DHCP server. To change the settings, check the official documentation.

The local network is set to `10.0.0.0/24`, and the PXE server must have the IP address `10.0.0.1`.

## Installation
You just need to run the `install.sh` script as root. It will install all the necessary packages, configure them, and start the services. The configuration is suitable for a Fedora PXE host, but it can be manually deployed for other distributions.

Note: You need an active Internet connection.

## How to boot
1. Connect the client machine to the local network of the PXE server (using an Ethernet cable) ;
2. Boot into network (IPv4).

If the client machine can't boot over network or if you don't want to allow it, you can use a Ventoy USB key and use network boot via iPXE ISO.

### Menu options
| Menu option | Description |
|-------------|-------------|
| Fedora 43 (Auto-install) | Fully automated installation of Fedora 43 (fetch files through HTTP) |
| Fedora 43 (Auto-install) - Fallback | Same as before but fetch files through TFTP |
| Reboot | Reboot the client machine |
| Shutdown | Shutdown the client machine |
| UEFI Firmware Settings | Access UEFI firmware settings (if supported) |

The fallback is automatically used if the first option fails. It can be useful if the client machine has issues with HTTP.

Those settings are set in the [GRUB configuration file](./pxe/grub.cfg).

## Fedora installation
As said, Fedora 43 Workstation will be installed on the computer. The installer is named `Anaconda` and shares the same specs than Red Hat OSes. The Kickstart file contains all the necessary information for the installation.

After booting via PXE, the installation should takes around 30min. The longer task is the disk formatting, and can take some hours depending of the size and type of the disk(s).

### What's happening during the installation of a computer?
You can see what the installer will do by checking the [Kickstart file](./pxe/fedora/ks.cfg). Mainly, the disk will be wiped and partitioned, the packages will be installed, and the system will be configured. The installer will also report the progress to the Reporter service.

However, some actions are recommended before, during and after the installation.

#### Before the installation
We recommend to reset the BIOS settings of the client machine before the installation. Make sure to set the best settings (regarding disk performances, etc). You'll need to enable the network boot.

### During the installation
A SSH server will be available during the installation. You can connect to it using the IP address of the client machine (provided by the DHCP server) and username/password `alias`. This can be useful to check the installation progress or to troubleshoot if an error occurs.

The installer will deploy a standard Fedora installation with the default settings, like the Live image. You can check the [Kickstart](./pxe/fedora/ks.cfg) file to see the exact configuration.

### Post-installation
After the installation, the client machine will be shutdown. You can now boot it normally and check if Fedora 43 is correctly installed. Also, you may disable the network boot in the BIOS settings to avoid any issue during the next boots.

## How-to prepare the `install.sh` script for a new Fedora version?
1. Run the GitHub Action [Update Fedora Version](https://github.com/alias-asso/donationware/actions/workflows/update-fedora-version.yml) ;
2. On a new virtual machine, deploy the PXE server using the branch created by the GitHub Action and check if everything is working properly (reporter, installation, etc.) ;
3. If everything is working properly, merge the branch to the main branch and delete it ;
4. Deploy the PXE server on the production machine and check if everything is working properly (reporter, installation, etc.) ;

# Reporter
The `/reporter` directory contains a NodeJS application. It's designed to send the data received from the DHCP server and Anaconda installer to Google Sheet and keep track of the installation process/computer specs.

It will need a Google Service Account with access to the Google Sheet. The credentials of the service account must be stored in a `credentials.json` file in the `/reporter` directory (or at the place specified in the service configuration).

Also, you'll need to have the [Google SpreadSheet ID](https://developers.google.com/workspace/sheets/api/guides/concepts), the [Sheet ID](https://developers.google.com/workspace/sheets/api/guides/concepts) and the Table ID.

## Get the Table ID
1. Go to the Google Developers Documentation
2. Click on `API` on the right menu
3. Filter using `Sheets`, click on `Google Sheets`, and then on `Try this API`
4. Select the `get` method
5. Provide the Spreadsheet ID
6. Click on `Execute` and check the response to get the Table ID

# Usefull links
- [Kickstart documentation](https://docs.redhat.com/fr/documentation/red_hat_enterprise_linux/7/html/installation_guide/sect-kickstart-syntax)
- [GRUB documentation](https://www.gnu.org/software/grub/manual/grub/grub.html#Network)
- [Google Sheet API documentation](https://developers.google.com/workspace/sheets/api/guides/concepts)
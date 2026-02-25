# Set here the Fedora version and the latest ISO name
version=43
iso_name="Fedora-Workstation-Live-$version-1.6.x86_64.iso"

# Define global paths/variables
fedora_release=http://download.fedoraproject.org/pub/fedora/linux/releases/$version
nfs_root=/srv/pxe
nfs_fedora_part=$nfs_root/f$version
nfs_fedora=$nfs_fedora_part/x86_64

# == Global setup ==
set -e
cd "$(dirname "$0")"

# Install all the packages
dnf install -y grub2-efi-x64-modules dhcp-server tftp-server nfs-utils nodejs-npm

# Start the TFTP server
systemctl start tftp.service
systemctl enable tftp.service

# Start the NFS server
mkdir -p $nfs_root
echo "$nfs_root 10.0.0.0/24(ro,sync,no_subtree_check)" >> /etc/exports
exportfs -ra
systemctl start nfs-server.service
systemctl enable nfs-server.service

# Enable DHCPD
systemctl enable dhcpd

# Setup firewall
firewall-cmd --permanent --add-service tftp
firewall-cmd --permanent --add-service dhcp
firewall-cmd --permanent --add-service nfs
firewall-cmd --reload

# == Boot ==
# Setup boot architecture
grub2-mknetdir --net-directory=/var/lib/tftpboot --subdir=/boot/grub -d /usr/lib/grub/i386-pc
grub2-mknetdir --net-directory=/var/lib/tftpboot --subdir=/boot/grub -d /usr/lib/grub/x86_64-efi

# Deploy Grub config
cp pxe/grub.cfg /var/lib/tftpboot/boot/grub/grub.cfg

# Setup boot files
mkdir -p /var/lib/tftpboot/f$version
wget $fedora_release/Server/x86_64/os/images/pxeboot/vmlinuz -O /var/lib/tftpboot/f$version/vmlinuz
wget $fedora_release/Server/x86_64/os/images/pxeboot/initrd.img -O /var/lib/tftpboot/f$version/initrd.img

# Duplicate boot files for NFS server
mkdir -p $nfs_fedora_part
ln -s /var/lib/tftpboot/f$version/ $nfs_fedora_part/f$version/

# === Deploy the Fedora image ===
mkdir -p $nfs_fedora/images

# Download Anaconda installer
wget $fedora_release/Server/x86_64/os/images/install.img -O $nfs_fedora/images/install.img

# Download the LiveCD image, extract the squashfs and deploy it
wget $fedora_release/Workstation/x86_64/iso/$iso_name -O /var/tmp/fedora-livecd.iso

mount -o loop /var/tmp/fedora-livecd.iso /mnt
cp /mnt/LiveOS/squashfs.img $nfs_fedora/images/
umount /mnt

rm -f /var/tmp/fedora-livecd.iso

# Deploy other files used by Anaconda (Installer)
cp pxe/fedora/* pxe/fedora/.treeinfo $nfs_fedora/

# Setup the DHCP server
cp pxe/dhcpd.conf /etc/dhcp/
cp pxe/dhcpd_send_mac.sh /usr/bin/
chmod 755 /usr/bin/dhcpd_send_mac.sh
systemctl restart dhcpd

# Setup permissions
chmod 755 -R $nfs_root
chmod 744 -R /var/lib/tftpboot

# Setup the reporter service
cp -R reporter/ /var/lib/reporter
npm install --prefix /var/lib/reporter
npm run build --prefix /var/lib/reporter

echo "Before continuing, please set the environment variables for the Google Sheets API (SPREADSHEET_ID, SHEET_ID and TABLE_ID) of the Reporter service."
pause "Press any key to open nano..."
nano reporter/reporter.service

mv /var/lib/reporter/reporter.service /etc/systemd/system/
systemctl daemon-reload
systemctl start reporter.service
systemctl enable reporter.service

# == Final notes ==
echo "PXE server setup is complete. Please setup your local network address to 10.0.0.1/24 to make it accessible."
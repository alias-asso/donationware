# Set here the Fedora version and the latest ISO name
version=42
iso_name="Fedora-Workstation-Live-$version-1.1.x86_64.iso"

# Define global paths/variables
fedora_release=http://download.fedoraproject.org/pub/fedora/linux/releases/$version
html=/var/www/html
html_fedora_part=$html/f$version
html_fedora=$html_fedora_part/x86_64

# == Global setup ==
# Install all the packages
dnf install -y grub2-efi-x64-modules dhcp-server tftp-server httpd dnf-plugins-core

# Start the TFTP server
systemctl start tftp.service
systemctl enable tftp.service

# Start the web server
systemctl start httpd.service
systemctl enable httpd.service

# Enable DHCPD
systemctl enable dhcpd

# Setup firewall
firewall-cmd --permanent --add-service tftp
firewall-cmd --permanent --add-service dhcp
firewall-cmd --permanent --add-service http
firewall-cmd --reload

# == Boot ==
# Setup boot architecture
grub2-mknetdir --net-directory=/var/lib/tftpboot --subdir=/boot/grub -d /usr/lib/grub/i386-pc
grub2-mknetdir --net-directory=/var/lib/tftpboot --subdir=/boot/grub -d /usr/lib/grub/x86_64-efi

# Deploy Grub config
cp grub.cfg /var/lib/tftpboot/boot/grub/grub.cfg

# Setup boot files
mkdir -p /var/lib/tftpboot/f$version
wget $fedora_release/Server/x86_64/os/images/pxeboot/vmlinuz -O /var/lib/tftpboot/f$version/vmlinuz
wget $fedora_release/Server/x86_64/os/images/pxeboot/initrd.img -O /var/lib/tftpboot/f$version/initrd.img

# Create symbolic links to also fetch vmlinux and initrd.img from the HTTP server
mkdir -p $html_fedora_part
ln -s $html_fedora_part /var/lib/tftpboot/f$version

# === Deploy the Fedora image ===
mkdir -p $html_fedora/images

wget $fedora_release/Workstation/x86_64/iso/$iso_name -O /var/tmp/fedora-livecd.iso

mount -o loop /var/tmp/fedora-livecd.iso /mnt
cp /mnt/LiveOS/squashfs.img $html_fedora/images/
umount /mnt

rm -f /var/tmp/fedora-livecd.iso

# Deploy the kickstart file
cp ks.cfg $html_fedora/ks.cfg

# == Network ==
# Setup the IP address of the server (at this step, it may lost the connection)
interface=$(ip a | grep ": eth" |  awk '{print $2}' | tr -d ':')
systemctl stop network.target
ifconfig $interface down
ifconfig $interface 192.168.1.1 netmask 255.255.255.0 up
systemctl start network.target

# Setup the DHCP server
cp dhcpd.conf /etc/dhcp/
systemctl restart dhcpd

# Setup permissions
chown -R apache:apache $html
chmod 755 -R /var/lib/tftpboot
# Set here the Fedora version
version=41

# Define global paths/variables
fedora_release=http://download.fedoraproject.org/pub/fedora/linux/releases/$version
html=/var/www/html
html_fedora=$html/fedora/$version/x86_64
aims=/srv/aims

# Install all the packages
dnf install -y tftp-server syslinux grub2-efi-x64-modules dhcp-server dnf-plugins-core createrepo_c httpd nodejs cronie

# Setup boot architecture
grub2-mknetdir --net-directory=/var/lib/tftpboot --subdir=/boot/grub -d /usr/lib/grub/i386-pc
grub2-mknetdir --net-directory=/var/lib/tftpboot --subdir=/boot/grub -d /usr/lib/grub/x86_64-efi

# Setup the TFTP server
systemctl start tftp.service
systemctl enable tftp.service

# Deploy syslinux
ln -s /usr/share/syslinux{pxelinux.0,vesamenu.c32,ldlinux.c32,libcom32.c32,libutil.c32} /var/lib/tftpboot/
mkdir -p /var/lib/tftpboot/pxelinux.cfg
cp default /var/lib/tftpboot/pxelinux.cfg/default

# Deploy grub
cp grub.cfg /var/lib/tftpboot/boot/grub/grub.cfg

# Setup boot files
mkdir -p /var/lib/tftpboot/f$version
wget $fedora_release/Server/x86_64/os/images/pxeboot/vmlinuz -O /var/lib/tftpboot/f$version/vmlinuz
wget $fedora_release/Server/x86_64/os/images/pxeboot/initrd.img -O /var/lib/tftpboot/f$version/initrd.img

# Start the web server
systemctl start httpd.service
systemctl enable httpd.service

# Deploy the Fedora image
mkdir -p $html_fedora/images
wget $fedora_release/Everything/x86_64/os/images/install.img -O $html_fedora/images/install.img

# Deploy the kickstart file
cp ks.cfg $html_fedora/ks.cfg

# Create a RPM repository
# Download each package using DNF from packages.txt
cat packages.txt | tr '\n' ' ' | xargs  dnf download --destdir=$html_fedora

mkdir -p $html_fedora/repodata
wget https://pagure.io/fedora-comps/raw/main/f/comps-f$version.xml.in -O $html_fedora/repodata/comps.xml
createrepo_c --groupfile $html_fedora/repodata/comps.xml $html_fedora

# Setup AIMS
mkdir -p $aims
cp -r aims/* $aims
cp -r aims_html/* $html
npm i --prefix $aims
node $aims/. &

crontab -l | { cat; echo "@reboot sh $aims/run_aims.sh"; }
crontab -

# Setup the IP address of the server (at this step, it may lost the connection)
interface=$(ip a | grep ": eth" |  awk '{print $2}' | tr -d ':')
systemctl stop network.target
ifconfig $interface down
ifconfig $interface 192.168.1.1 netmask 255.255.255.0 up
systemctl start network.target

# Setup the DHCP server
cp dhcpd.conf /etc/dhcp/
cp dhcp_on_commit.sh /usr/local/bin
systemctl restart dhcpd

# Setup firewall
firewall-cmd --permanent --add-service tftp
firewall-cmd --permanent --add-service dhcp
firewall-cmd --permanent --add-service http
firewall-cmd --reload

# Setup permissions
chown -R apache:apache $html
chown -R apache:apache $aims
chmod 755 -R /var/lib/tftpboot
chmod 755 /usr/bin/local/dhcp_on_commit.sh
# Ubuntu 14.04 LTS kickstart for XenServer
# branch: Ubuntu1404
##########################################

# Install, not upgrade
install

# Install from a friendly mirror and add updates
url --url http://us.archive.ubuntu.com/ubuntu/

# Language and keyboard setup
lang en_US
langsupport en_US
keyboard us

# Configure networking without IPv6, firewall off

# for STATIC IP: uncomment and configure
network --device=eth0 --bootproto=static --ip=192.168.81.30 --netmask=255.255.255.0 --gateway=192.168.81.1 --nameserver=192.168.81.1 --hostname=ubuntu0

# for DHCP:
network --bootproto=dhcp --device=eth0

firewall --enabled --ssh

# Set timezone
#timezone --utc America/Los_Angeles
timezone America/Los_Angeles

# Authentication
rootpw --disabled
user ubuntu --fullname "Ubuntu User" --password Asdfqwerty
user MySecretUser --fullname "MySecretName" --password MySecretPassword
# if you want to preset the root password in a public kickstart file, use SHA512crypt e.g.
# user ubuntu --fullname "Ubuntu User" --iscrypted --password $6$9dC4m770Q1o$FCOvPxuqc1B22HM21M5WuUfhkiQntzMuAV7MY0qfVcvhwNQ2L86PcnDWfjDd12IFxWtRiTuvO/niB0Q3Xpf2I.
auth --useshadow

# Disable anything graphical
skipx
text

# Setup the disk
zerombr yes
clearpart --all
part /boot --fstype=ext3 --size=256 --asprimary
part swap --size 1024
part / --fstype=ext4 --grow --size=1024 --asprimary
bootloader --location=mbr

# Shutdown when the kickstart is done
halt

# Minimal package set
%packages
ubuntu-minimal
openssh-server
screen
curl
wget
xenstore-utils
linux-image-virtual

%post
#!/bin/sh
echo -n "Minimizing kernel"
apt-get install -f -y linux-virtual
apt-get remove -y linux-firmware
dpkg -l | grep extra | grep linux | awk '{print $2}' | xargs apt-get remove -y
echo .

echo -n "/etc/fstab fixes"
# update fstab for the root partition
perl -pi -e 's/(errors=remount-ro)/noatime,nodiratime,$1,barrier=0/' /etc/fstab
echo .

echo -n "Network fixes"
# For cloud images, 'eth0' _is_ the predictable device name, since
# we don't want to be tied to specific virtual (!) hardware
rm -f /etc/udev/rules.d/70*
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
echo .

# generic localhost names
echo "ubuntu0" > /etc/hostname
echo .
cat > /etc/hosts << EOF
127.0.0.1   localhost ubuntu0
::1         localhost ubuntu0

EOF
echo .

# utility scripts
echo -n "Utility scripts"
wget -O /opt/domu-hostname.sh https://raw.githubusercontent.com/c0mpiler/KickStart-XenServer/master/opt/domu-hostname.sh
chmod +x /opt/domu-hostname.sh
echo .
wget -O /opt/generate-sshd-keys.sh https://raw.githubusercontent.com/c0mpiler/KickStart-XenServer/master/opt/generate-sshd-keys.sh
chmod +x /opt/generate-sshd-keys.sh
echo .

# generalization
echo -n "Generalizing"
rm -f /etc/ssh/ssh_host_*
rm -f /var/cache/apt/archives/*.deb
rm -f /var/cache/apt/*cache.bin
rm -f /var/lib/apt/lists/*_Packages
echo .

#force_color_prompt
sed -i 's,#force_color_prompt=yes,force_color_prompt=yes,g' /home/harsha/.bashrc
#sed -i 's,#force_color_prompt=yes,force_color_prompt=yes,g' /home/ubuntu/.bashrc

# re-configure ssh-server
dpkg-reconfigure openssh-server

#install a few required packages
apt-get install -y git htop 

# Adding puppet repositories
wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
sudo dpkg -i puppetlabs-release-precise.deb
apt-get update -y

# Installing puppet
apt-get install -y puppet
#puppet resource service puppet ensure=running enable=true
#puppet resource cron puppet-agent ensure=present user=root minute=30 command='/usr/bin/puppet agent --onetime --no-daemonize --splay'

# fix boot for older pygrub/XenServer
# you should comment out this entire section if on XenServer Creedence/Xen 4.4
echo -n "Fixing boot"
cp /boot/grub/grub.cfg /boot/grub/grub.cfg.bak
cp /etc/default/grub /etc/default/grub.bak
cp --no-preserve=mode /etc/grub.d/00_header /etc/grub.d/00_header.bak
sed -i 's/GRUB_DEFAULT=saved/GRUB_DEFAULT=0/' /etc/default/grub
sed -i 's/default="\\${next_entry}"/default="0"/' /etc/grub.d/00_header
echo -n "."
cp --no-preserve=mode /etc/grub.d/10_linux /etc/grub.d/10_linux.bak
sed -i 's/${sixteenbit}//' /etc/grub.d/10_linux
echo -n "."
update-grub
echo .

%end

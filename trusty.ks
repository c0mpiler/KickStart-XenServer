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
network --device=eth0 --bootproto=static --ip=192.168.81.30 --netmask=255.255.255.0 --gateway=192.168.81.1 --nameserver=192.168.81.1 --hostname=ubuntuZero

# for DHCP:
network --bootproto=dhcp --device=eth0

firewall --enabled --ssh

# Set timezone
#timezone --utc America/Los_Angeles
timezone America/Los_Angeles

# Authentication
rootpw --disabled
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
make
build-essential 
libcurl4-openssl-dev
libssl-dev 
zlib1g-dev
ruby-dev 
libapr1-dev 
libaprutil1-dev

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
echo "ubuntuZero" > /etc/hostname
echo .
cat > /etc/hosts << EOF
127.0.0.1   localhost ubuntuZero
127.0.1.1   ubuntuZero

192.168.81.100  puppet
192.168.81.101  ubuntu01
192.168.81.102  ubuntu02
192.168.81.103  ubuntu03
192.168.81.104  ubuntu04
192.168.81.105  ubuntu05
192.168.81.106  ubuntu06
192.168.81.107  ubuntu07
192.168.81.108  ubuntu08
192.168.81.109  ubuntu09
192.168.81.110  ubuntu10
192.168.81.111  ubuntu11
192.168.81.112  ubuntu12
192.168.81.113  ubuntu13
192.168.81.114  ubuntu14
192.168.81.115  ubuntu15
192.168.81.116  ubuntu16
192.168.81.117  ubuntu17
192.168.81.118  ubuntu18
192.168.81.119  ubuntu19
192.168.81.120  ubuntu20
192.168.81.121  ubuntu21
192.168.81.122  ubuntu22
192.168.81.123  ubuntu23
192.168.81.124  ubuntu24
192.168.81.125  ubuntu25
192.168.81.126  ubuntu26
192.168.81.127  ubuntu27
192.168.81.128  ubuntu28
192.168.81.129  ubuntu29
192.168.81.130  ubuntu30
192.168.81.131  ubuntu31
192.168.81.132  ubuntu32
192.168.81.133  ubuntu33
192.168.81.134  ubuntu34
192.168.81.135  ubuntu35
192.168.81.136  ubuntu36
192.168.81.137  ubuntu37
192.168.81.138  ubuntu38
192.168.81.139  ubuntu39
192.168.81.140  ubuntu40
192.168.81.141  ubuntu41
192.168.81.142  ubuntu42
192.168.81.143  ubuntu43
192.168.81.144  ubuntu44
192.168.81.145  ubuntu45
192.168.81.146  ubuntu46
192.168.81.147  ubuntu47
192.168.81.148  ubuntu48
192.168.81.149  ubuntu49
192.168.81.150  ubuntu50

EOF
echo .

# utility scripts
echo -n "Utility scripts"
wget -O /opt/domu-hostname.sh https://raw.githubusercontent.com/c0mpiler/KickStart-XenServer/master/opt/domu-hostname.sh
chmod +x /opt/domu-hostname.sh
echo .
wget -O /opt/generate-sshd-keys.sh https://raw.githubusercontent.com/c0mpiler/KickStart-XenServer/master/opt/generate-sshd-keys.sh
chmod +x /opt/generate-sshd-keys.sh

dpkg-reconfigure openssh-server
apt-get install -f -y git nodejs nodejs-dev htop dnstop dnstracer

wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb
sudo dpkg -i puppetlabs-release-precise.deb
apt-get update -y

apt-get install -y puppet

echo .

# generalization
echo -n "Generalizing"
rm -f /etc/ssh/ssh_host_*
rm -f /var/cache/apt/archives/*.deb
rm -f /var/cache/apt/*cache.bin
rm -f /var/lib/apt/lists/*_Packages
sed -i 's,#force_color_prompt=yes,force_color_prompt=yes,g' /home/harsha/.bashrc
sed -i 's,#force_color_prompt=yes,force_color_prompt=yes,g' /root/.bashrc
echo .

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

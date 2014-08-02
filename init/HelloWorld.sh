sudo dpkg-reconfigure openssh-server
sed -i 's,#force_color_prompt=yes,force_color_prompt=yes,g' /root/.bashrc
source /root/.bashrc

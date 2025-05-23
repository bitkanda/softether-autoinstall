#!/bin/bash

# Define console colors
RED='\033[0;31m'
NC='\033[0m' # No Color
(( EUID != 0 )) && exec sudo -- "$0" "$@"
clear

# User confirmation
read -r -p "This will install SoftEther to your server. Are you sure you want to continue? [y/N] " response
case $response in
[yY][eE][sS]|[yY])

# Create & CD into working directory
printf "\nMaking sure that there are no previous SoftEther downloads/folders in this current directory.\n\n"
cd ~ && rm -rf se-vpn > /dev/null 2>&1
cd ~ && mkdir se-vpn && cd se-vpn
rm /etc/systemd/system/vpnserver.service > /dev/null 2>&1

# Install Development Tools & kernel-devel
printf "\n${RED}Development Tools${NC} are required. Installing those now.\n\n"
yum update -y && yum groupinstall "Development Tools" -y && yum install kernel-devel -y

# Download SoftEther | Version 4.34 | Build 9745
printf "\nDownloading last stable release: ${RED}4.27${NC} | Build ${RED}9668${NC}\n\n"
curl -o softether-vpn-4.34.tar.gz https://www.softether-download.com/files/softether/v4.34-9745-rtm-2020.04.05-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.34-9745-rtm-2020.04.05-linux-x64-64bit.tar.gz
tar -xzf softether-vpn-4.34.tar.gz
cd vpnserver
echo $'1\n1\n1' | make
cd ~/se-vpn
#cd ~
mv vpnserver/ /usr/local/
chmod 600 /usr/local/vpnserver/* && chmod 700 /usr/local/vpnserver/vpncmd && chmod 700 /usr/local/vpnserver/vpnserver
#cd ~/se-vpn && curl -o vpnserver-init https://raw.githubusercontent.com/dovanpho/softether-autoinstall/refs/heads/master/vpnserver-init
cd ~/se-vpn && curl -o vpnserver-init https://raw.githubusercontent.com/bitkanda/softether-autoinstall/refs/heads/master/vpnserver.service
mv vpnserver-init /etc/systemd/system/vpnserver.service
chmod 755 /etc/systemd/system/vpnserver.service
printf "\nSystem daemon created. Registering changes...\n\n"
#chkconfig --add vpnserver


#需要下载文件生成守护进程才行。
#刷新


printf "\nSoftEther VPN Server should now start as a system service from now on.\n\n"

# Open ports for SoftEther VPN Server using firewalld
printf "\nNow opening ports for SSH and SoftEther.\n\nIf you use another port for SSH, please run ${RED}firewall-cmd --zone=public --permanent --add-port=x/tcp${NC} where x = your SSH port.\n\n"
echo '<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>sevpn</short>
  <description>SoftEther VPN Server</description>
  <port protocol="tcp" port="443"/>
  <port protocol="tcp" port="1194"/>
  <port protocol="tcp" port="5555"/>
  <port protocol="tcp" port="992"/>
  <port protocol="udp" port="500"/>
  <port protocol="udp" port="1701"/>
  <port protocol="udp" port="4500"/>
</service>' > /etc/firewalld/services/sevpn.xml
systemctl start firewalld
firewall-cmd --reload
firewall-cmd --zone=public --permanent --add-service=sevpn
firewall-cmd --zone=public --permanent --add-service=ssh
firewall-cmd --reload
#systemctl start vpnserver
systemctl daemon-reload

sudo systemctl enable vpnserver
sudo systemctl start vpnserver
sudo systemctl status vpnserver


printf "\nCleaning up...\n\n"
cd ~ && rm -rf se-vpn/ > /dev/null 2>&1
#systemctl status vpnserver
printf "\nIf the output above shows vpnserver.service to be active (running), then SoftEther VPN has been successfully installed and is now running.\nTo configure the server, use the SoftEther VPN Server Manager located here: https://bit.ly/2NFGNWa\n\n"
esac

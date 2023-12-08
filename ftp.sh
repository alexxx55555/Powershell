#!/bin/bash

# Step 1: Install vsftpd package
sudo apt update
sudo apt install -y vsftpd

# Step 2: Configure vsftpd for AD authentication
cat <<EOL | sudo tee /etc/vsftpd.conf
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_enable=Yes
pasv_min_port=10000
pasv_max_port=10100
EOL

# Step 3: Configure PAM for vsftpd to use sssd for AD authentication
echo "auth required pam_sss.so" | sudo tee /etc/pam.d/vsftpd
echo "account required pam_sss.so" | sudo tee -a /etc/pam.d/vsftpd

# Step 4: Ensure vsftpd is started and enabled at boot
sudo systemctl enable vsftpd
sudo systemctl start vsftpd

echo "FTP server is set up and integrated with alex.local AD!"


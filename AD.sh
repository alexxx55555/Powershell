#!/bin/bash

# Step 1: Install necessary packages
sudo apt update
sudo apt upgrade -y
sudo apt install sssd heimdal-clients msktutil -y

# Step 2: Update Kerberos configuration
sudo mv /etc/krb5.conf /etc/krb5.conf.default
echo "[libdefaults]
default_realm = ALEX.LOCAL
rdns = no
dns_lookup_kdc = true
dns_lookup_realm = true

[realms]
ALEX.LOCAL = {
    kdc = dc1.alex.local
    admin_server = dc1.alex.local
}" | sudo tee /etc/krb5.conf

# Step 3: Initialize Kerberos and generate a keytab file
kinit vinokura
klist
msktutil -N -c -b 'CN=COMPUTERS' -s Ubuntu-Desktop/Ubuntu-Desktop.alex.local -k my-keytab.keytab --computer-name Ubuntu-Desktop --upn Ubuntu-Desktop$ --server dc1.alex.local --user-creds-only
msktutil -N -c -b 'CN=COMPUTERS' -s Ubuntu-Desktop/Ubuntu-Desktop -k my-keytab.keytab --computer-name Ubuntu-Desktop --upn Ubuntu-Desktop$ --server dc1.alex.local --user-creds-only
kdestroy

# Step 4: Configure SSSD
sudo mv my-keytab.keytab /etc/sssd/my-keytab.keytab
echo "[sssd]
services = nss, pam
config_file_version = 2
domains = alex.local

[nss]
entry_negative_timeout = 0

[pam]

[domain/alex.local]
enumerate = false
id_provider = ad
auth_provider = ad
chpass_provider = ad
access_provider = ad
dyndns_update = false
ad_hostname = Ubuntu-Desktop.alex.local
ad_server = dc1.alex.local
ad_domain = alex.local
ldap_schema = ad
ldap_id_mapping = true
fallback_homedir = /home/%u
default_shell = /bin/bash
ldap_sasl_mech = gssapi
ldap_sasl_authid = Ubuntu-Desktop$
krb5_keytab = /etc/sssd/my-keytab.keytab
ldap_krb5_init_creds = true" | sudo tee /etc/sssd/sssd.conf
sudo chmod 0600 /etc/sssd/sssd.conf

# Step 5: Configure PAM
sudo sed -i '/session required pam_unix.so/a session required pam_mkhomedir.so skel=/etc/skel umask=0077' /etc/pam.d/common-session
sudo systemctl restart sssd

# Step 6: Add the domain administrator to the local admin group
sudo adduser vinokura sudo




# Step 7: Install and configure vsftpd
sudo apt install vsftpd -y

# Back up the original configuration file
sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.original

# Add/Modify the following settings in vsftpd.conf for AD integration
echo "
listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
ssl_enable=NO

# Integration with AD through PAM
session_support=YES" | sudo tee -a /etc/vsftpd.conf

# Modify PAM configuration for vsftpd to use SSSD for authentication
echo "
auth required pam_sss.so
account required pam_sss.so
session required pam_sss.so" | sudo tee /etc/pam.d/vsftpd

# Restart the vsftpd service to apply the changes
sudo systemctl restart vsftpd

# Ensure vsftpd starts at boot
sudo systemctl enable vsftpd
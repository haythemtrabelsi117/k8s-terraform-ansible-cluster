echo "################################################################################" >> /tmp/vagrant-provision.log
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config    
systemctl restart sshd.service
echo "################################################################################" >> /tmp/vagrant-provision.log

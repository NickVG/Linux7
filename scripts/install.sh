#! /bin/bash

# TASK 1
echo "------ Start Task 1 ------"
cp /vagrant/files/watchlog /etc/sysconfig/watchlog
cp /vagrant/files/watchlog.sh /opt/watchlog.sh
chmod +x /opt/watchlog.sh
cp /vagrant/files/watchlog.service /etc/systemd/system/watchlog.service
cp /vagrant/files/watchlog.timer /etc/systemd/system/watchlog.timer

systemctl enable watchlog.timer --now

# TASK 2
"------ Start Task 2 ------"
yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y

cp /vagrant/files/spawn-fcgi /etc/sysconfig/spawn-fcgi 
cp /vagrant/files/spawn-fcgi.service /etc/systemd/system/spawn-fcgi.service

systemctl enable spawn-fcgi --now

/vagrant/scripts/httpd_twice.sh

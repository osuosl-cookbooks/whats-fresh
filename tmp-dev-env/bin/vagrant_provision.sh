#!/bin/bash

# Shell script to provision the vagrant box.

cd /home/vagrant/project/

sudo yum -y install curl

curl -O http://dl.iuscommunity.org/pub/ius/stable/CentOS/6/x86_64/ius-release-1.0-13.ius.centos6.noarch.rpm

sudo yum install -y ius-release-1.0-13.ius.centos6.noarch.rpm 

#install the yum-ius repo which has python 2.7
sudo yum -y install python-virtualenv git postgresql-server postgresql python27

sudo service postgresql initdb << end
    whats_fresh
end
sudo service postgresql start

runuser -l postgres -c 'psql whats_fresh -c "CREATE EXTENSION postgis;"'



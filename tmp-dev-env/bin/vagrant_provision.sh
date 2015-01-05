#!/bin/bash

# Shell script to provision the vagrant box.

cd /home/vagrant/project/

#install the yum-ius repo which has python 2.7
sudo yum -y install python-virtualenv git postgresql python27
runuser -l postgres -c 'psql whats_fresh -c "CREATE EXTENSION postgis;"'



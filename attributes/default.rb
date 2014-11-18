#
# Cookbook Name:: windows_network
# Recipe:: default
#
# License: Apache license 2
#
# Authors
# Christoffer Järnåker, Proxmea BV, 2014
# Christoffer Järnåker, Schuberg Philis, 2014


default['windows_network']['databag_name'] = "server" 

# Data types:
# 1  'Server' data bag, <hostname> item, 'interfaces' ...
# 2  'udev' data bag, <hostname> item, <nic name>  ...
default['windows_network']['datatype'] = 1 
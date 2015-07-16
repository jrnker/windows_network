#
# Cookbook Name:: windows_network
# Recipe:: default
#
# License: Apache license 2
#
# Authors
# Christoffer Järnåker, Proxmea BV, 2014
# Christoffer Järnåker, Schuberg Philis, 2014

# Output more data to screen
default['windows_network']['showlog'] = false 

# Specify which data bag will contain the interface information
default['windows_network']['databag_name'] = "servers" 

# Specify which environment attribute will hold the windows domain information (DNS stuff)
default['windows_network']['env_att_name'] = "win_domain" 

# Data types:
# 1  'Server' data bag, <hostname> item, 'interfaces' ...
# 2  'udev' data bag, <hostname> item, <nic name>  ...
default['windows_network']['datatype'] = 1 


# Some attributes to be able to enable disable the subsections 
default['windows_network']['setInterfaceIP'] = true 
default['windows_network']['setInterfaceName'] = true 
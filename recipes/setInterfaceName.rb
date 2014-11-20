#
# Cookbook Name:: windows_network
# Recipe:: setInterfaceName.rb
#
# License: Apache license 2
#
# Authors
# Christoffer Järnåker, Proxmea BV, 2014
# Christoffer Järnåker, Schuberg Philis, 2014
#

####################################################################################################
### Check and update network interfaces name                                                     ###
####################################################################################################
if_keys = node['network']['interfaces'].keys
if_keys.each do |iface|
  hostname = node['hostname'].downcase
  macaddress = node['network']['interfaces'][iface]['addresses'].to_hash.select {|addr, debug| debug["family"] == "lladdr"}.flatten.first
  mac = macaddress.upcase

  ifname = r_d('powershell -noprofile -command "(Get-WmiObject Win32_NetworkAdapter | where{$_.MacAddress -eq """' + mac + '"""}).NetconnectionId"')
  newnet = getnetname(macaddress,hostname,$getfirstconfig) 

  linfo("Network names:")
  linfo("  ifname #{ifname}")
  linfo("  newnet #{newnet}")

  if (ifname != newnet) && (newnet != nil) 
    Chef::Log.info("Renaming \"#{ifname}\" to \"#{newnet}\"") 
    r_d('netsh interface set interface name="' + ifname +'" newname="' + newnet + '"')
  end 
end 

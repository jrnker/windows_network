#
# Cookbook Name:: windows_network
# Recipe:: default
#
# License: Apache license 2
#
# Authors
# Christoffer Järnåker, Proxmea BV, 2014
# Christoffer Järnåker, Schuberg Philis, 2014
#

if platform?("windows")
 
  ####################################################################################################
  ### Check and load prerequisite attributes                                                       ###
  ####################################################################################################
  $databag_name = node['windows_network']['databag_name']
  $env_att_name = node['windows_network']['env_att_name']
  $datatype = node['windows_network']['datatype'] 
  $getfirstconfig = false
  linfo("databag_name #{$databag_name}")
  linfo("env_att_name #{$env_att_name}")
  linfo("datatype #{$datatype}")
     
  if !Chef::DataBag.list.key?($databag_name)
    Chef::Log.error("Data bag #{$databag_name} doesn't exist - exiting")
    return 
  end
  
  include_recipe 'windows_network::setInterfaceIP' if node['windows_network']['setInterfaceIP'] == true 
  include_recipe 'windows_network::setInterfaceName' if node['windows_network']['setInterfaceName'] == true 
  
  # ohai 'chef' do
  #   action :reload
  #   not_if $nodeUpdated == false
  # end

  ohai "net_reload" do
    action :nothing
    plugin "network"
  end

  ruby_block "bla" do
    block do 
      #if (newnet != nil) 
      # doaction("Renaming \"#{ifname}\" to \"#{newnet}\"",\
      #        'netsh interface set interface name="' + ifname +'" newname="' + newnet + '"',\
      #        (ifname != newnet))
      puts "Hello ;)"
      #end 
    end
    notifies :reload, "ohai[net_reload]", :immediately
    # only_if newnet != nil
  end



 end

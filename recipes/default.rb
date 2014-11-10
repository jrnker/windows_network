#
# Cookbook Name:: windows_network
# Recipe:: default
#
# Copyright 2014, Proxmea BV
#

if platform?("windows")

  ####################################################################################################
  ### Check and update network interfacess ip configuration                                        ###
  ####################################################################################################
  if_keys = node[:network][:interfaces].keys
  if_keyscount = if_keys.count
  hostname = node.hostname.downcase
  getnetcount = getnetcount(hostname)
  Chef::Log.debug("Data bag interface count: #{getnetcount}") 
  Chef::Log.debug("Actual interface count: #{if_keyscount}") 
  if if_keyscount == 1 and getnetcount == 1
    getfirstconfig = "true"
  end

  if_keys.each do |iface|

    # First off, let's collect some 'official' data that we can use later 
    ifname = node[:network][:interfaces][iface][:instance][:net_connection_id]
    dhcp = node[:network][:interfaces][iface][:configuration][:dhcp_enabled]
    
    dns = Array.new
    $i = 0
    node[:network][:interfaces][iface][:configuration][:dns_server_search_order].each do |object|
      dns[$i] = object
      $i += 1
    end

    ipaddress = node[:network][:interfaces][iface][:addresses].to_hash.select {|addr, debug| debug["family"] == "inet"}.flatten.first
    macaddress = node[:network][:interfaces][iface][:addresses].to_hash.select {|addr, debug| debug["family"] == "lladdr"}.flatten.first

    Chef::Log.debug("Node based values:")
    Chef::Log.debug("  iface #{iface}")
    Chef::Log.debug("  ifname #{ifname}")
    Chef::Log.debug("  macaddress #{macaddress}")
    Chef::Log.debug("  ipaddress #{ipaddress}")
    $i = 0
    dns.each do |object|
      Chef::Log.debug("  dns[#{$i}] #{dns[$i]}")
      $i += 1
    end 
    Chef::Log.debug("  dhcp #{dhcp}")

    # Now, let's get the environment wide DNS settings
    wd_DomainDNSName = node['win_domain']['DomainDNSName']
    wd_dns = Array.new
    wd_dns[0] = node['win_domain']['DNS1']
    wd_dns[1] = node['win_domain']['DNS2']
    wd_dns[2] = node['win_domain']['DNS3'] 

    Chef::Log.debug("Environment wide values:")
    Chef::Log.debug("  wd_DomainDNSName #{wd_DomainDNSName}") 
    $i = 0
    wd_dns.each do |object|
      Chef::Log.debug("  wd_dns[#{$i}] #{wd_dns[$i]}")
      $i += 1
    end 

    # We first get the network name and put it in 'net', and then use this to retrieve the settings
    #
    # If we only have one NIC and there os only one NIC specified in the data bag, then this will be used.
    # In this case the "mac" can be omitted from the databag

    net = getnet(macaddress,hostname,getfirstconfig)
    if net == nil
      Chef::Log.warn("No configuration found for #{macaddress} in data bag servers #{hostname}. You might want to add it...")
    else 
      newip = getval("address",net,hostname)
      newsubnet = getval("netmask",net,hostname)
      newdfgw = getval("gateway",net,hostname)  
      newdnsdata = getval("dns-nameservers",net,hostname)
      newdns = Array.new
      if newdnsdata != nil
        newdns = newdnsdata.split(",")  
      end
      newdnssearch = getval("dns-search",net,hostname) 
      
      Chef::Log.debug("Node specific values:") 
      Chef::Log.debug("  net #{net}")
      Chef::Log.debug("  newip #{newip}")
      Chef::Log.debug("  newsubnet #{newsubnet}")
      Chef::Log.debug("  newdfgw #{newdfgw}")
      $i = 0
      dns.each do |object|
        Chef::Log.debug("  newdns[#{$i}] #{newdns[$i]}")
        $i += 1
      end

      if newip != nil 
        if (newip.downcase == "dhcp") && (dhcp == false)
          Chef::Log.info("Changing ip from #{ipaddress} to DHCP on #{ifname}")
          `netsh interface ip set address \"#{ifname}\" dhcp` 
          sleep(5)
        else
          if newsubnet != nil
            if not ipaddress == newip 
              Chef::Log.info("Changing ip from #{ipaddress} to #{newip} on #{ifname}")
              `netsh interface ip set address \"#{ifname}\" static \"#{newip}\" \"#{newsubnet}\" \"#{newdfgw}\"`  
            end 
          end
        end
      end 
    end

    ####################################################################################################
    ### Check and update DNS configuration                                                           ###
    ####################################################################################################
    # Determine which DNS values to use. 
    # We prefer, in order: node specific, environment specific, previous
    # Previous can thus be what DHCP has set it to be

    bestdns = Array.new
    $i = 0 
    while $i < 2  do 
      bestdns[$i] = newdns[$i]
      if bestdns[$i] == nil 
        bestdns[$i] = wd_dns[$i]
        if bestdns[$i] == nil
          bestdns[$i] = dns[$i]
        end
      end 
      $i +=1
    end

    Chef::Log.debug("We consider these to be the best DNS's to use:")  
    $i = 0
    dns.each do |object|
      Chef::Log.debug("  bestdns[#{$i}] #{bestdns[$i]}")
      $i += 1
    end

    mac = macaddress.upcase
    actualdnsdata = `powershell -noprofile -command "(Get-WmiObject Win32_NetworkAdapterConfiguration | where{$_.MacAddress -eq '#{mac}'}).DnsServerSearchOrder"` 
    actualdnssuffix = registry_get_values("HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\services\\Tcpip\\Parameters").find_all{|item| item[:name] == "SearchList"}[0][:data]
    actualdhcpdata =      `powershell -noprofile -command "(Get-WmiObject Win32_NetworkAdapterConfiguration | where{$_.MacAddress -eq '#{mac}'}).DHCPEnabled"`.gsub(/\n/,"")  
    if actualdnsdata != nil
      actualdns = actualdnsdata.split(/\n/)
    end
    if actualdhcpdata != nil
      actualdhcp = actualdhcpdata.downcase
    end

    Chef::Log.debug("Values from actual system:") 
    $i = 0
    dns.each do |object|
      Chef::Log.debug("  actualdns[#{$i}] #{actualdns[$i]}")
      $i += 1
    end
    Chef::Log.debug("  actualdnssuffix #{actualdnssuffix}")
    Chef::Log.debug("  actualdhcp #{actualdhcp}")

    # Compare the best and actual values, and if different set dns. Maximum of three DNS's
    $i = 0
    while $i < 2 do
      if (actualdns[$i] != bestdns[$i]) && (bestdns[$i] != nil)
        updatedns = "true"
      end
      $i += 1
    end

    # Okay, let's set the dns values
    Chef::Log.debug("updatedns #{updatedns}")
    if updatedns == "true"
      $i = 0
      bestdns.each do |object|
        if $i == 0 
          Chef::Log.info("Setting DNS#{$i} on #{ifname} to #{bestdns[$i]}") 
          `netsh interface ipv4 set dns name=\"#{ifname}\" source=static address=\"#{bestdns[$i]}\"`
        else
          Chef::Log.info("Setting DNS#{$i} on #{ifname} to #{bestdns[$i]} as index #{$i+1}") 
          `netsh interface ipv4 add dns name=\"#{ifname}\" address=\"#{bestdns[$i]}\" index=#{$i+1}`
        end
        $i += 1
      end 
    end

    # The dns search is system wide, though it will be applied per interface. Last one wins ;)
    if newdnssearch != nil && actualdnssuffix != newdnssearch
    Chef::Log.info("Setting DNS search suffix list to  #{newdnssearch}")
      registry_key "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\services\\Tcpip\\Parameters" do
        values [{
          :name => "SearchList",
          :type => :string ,
          :data => newdnssearch
          }]
          action :create 
      end
    end

  end




  ####################################################################################################
  ### Check and update network interfaces name                                                     ###
  ####################################################################################################
  if_keys = node[:network][:interfaces].keys
  if_keys.each do |iface|
    hostname = node.hostname.downcase
    macaddress = node[:network][:interfaces][iface][:addresses].to_hash.select {|addr, debug| debug["family"] == "lladdr"}.flatten.first
    mac = macaddress.upcase

    ifname = `powershell -noprofile -command "(Get-WmiObject Win32_NetworkAdapter | where{$_.MacAddress -eq '#{mac}'}).NetconnectionId"`.gsub(/\n/,"")
    newnet = getnet(macaddress,hostname,getfirstconfig) 

    Chef::Log.debug("Network names:")
    Chef::Log.debug("  ifname #{ifname}")
    Chef::Log.debug("  newnet #{newnet}")

    if (ifname != newnet) && (newnet != nil) 
      Chef::Log.info("Renaming \"#{ifname}\" to \"#{newnet}\"")
      `netsh interface set interface name=\"#{ifname}\" newname=\"#{newnet}\"`
    end 
  end 
end
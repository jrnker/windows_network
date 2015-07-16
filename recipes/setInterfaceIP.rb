#
# Cookbook Name:: windows_network
# Recipe:: setInterfaceIP.rb
#
# License: Apache license 2
#
# Authors
# Christoffer Järnåker, Proxmea BV, 2014
# Christoffer Järnåker, Schuberg Philis, 2014
#

####################################################################################################
### Check and update network interfacess ip configuration                                        ###
####################################################################################################
if_keys = node['network']['interfaces'].keys
if_keyscount = if_keys.count
hostname = node['hostname'].downcase
getnetcount = getnetcount(hostname)
linfo("Data bag interface count: #{getnetcount}") 
linfo("Actual interface count: #{if_keyscount}") 
if if_keyscount == 1 and getnetcount == 1
  $getfirstconfig = "true"
end
$showlog=true
# Iterate through all network interfaces
if_keys.each do |iface|

  # First off, let's collect some 'official' data that we can use later 
  ifname = node['network']['interfaces'][iface]['instance']['net_connection_id']
  dhcp = node['network']['interfaces'][iface]['configuration']['dhcp_enabled']
  
  dns = Array.new
  $i = 0
  if node['network']['interfaces'][iface]['configuration']['dns_server_search_order'] != nil
    node['network']['interfaces'][iface]['configuration']['dns_server_search_order'].each do |object|
      dns[$i] = object
      $i += 1
    end
  end  

  # Let's build up this interface ip addresses
  ipaddresses = Array.new
  inet = node['network']['interfaces'][iface]['addresses'].to_hash.select {|addr, debug| debug["family"] == "inet"}
  inet.each do|k,a|
    ipaddresses.push(k)
  end

  #ipaddresses = node['network']['interfaces'][iface]['addresses'].to_hash.select {|addr, debug| debug["family"] == "inet"}
  macaddress = node['network']['interfaces'][iface]['addresses'].to_hash.select {|addr, debug| debug["family"] == "lladdr"}.flatten.first
  dfgw = node['network']['interfaces'][iface]['configuration']['default_ip_gateway']
  dfgw = dfgw.flatten.first if dfgw != nil
  dfgw = "" if dfgw == nil

  linfo("Node based values:")
  linfo("  iface #{iface}")
  linfo("  ifname #{ifname}")
  linfo("  dfgw #{dfgw}")
  linfo("  macaddress #{macaddress}")
  linfo("  ipaddresses #{ipaddresses}")
  $i = 0
  dns.each do |object|
    linfo("  dns[#{$i}] #{dns[$i]}")
    $i += 1
  end 
  linfo("  dhcp #{dhcp}")

  # We first get the network name and put it in 'net', and then use this to retrieve the settings
  #
  # If we only have one NIC and there os only one NIC specified in the data bag, then this will be used.
  # In this case the "mac" can be omitted from the databag

  net = getnet(macaddress,hostname,$getfirstconfig)
  newdns = Array.new
  if net == nil
    Chef::Log.warn("No configuration found for #{macaddress} in data bag #{$databag_name} #{hostname}. You might want to add it...")
  else 
	
  	newipdata = getval("address",net,hostname)
  	newip = newipdata.split(",") if newipdata != nil	
  	newsubnetdata = getval("netmask",net,hostname)
    newsubnet = newsubnetdata.split(",") if newsubnetdata != nil		
    newdfgw = getval("gateway",net,hostname)  # Note for datatype 2, that you first need to retrieve IP and subnets first, as these are used later for the defgw
    newdfgw = "" if newdfgw == nil
    newdnsdata = getval("dns-nameservers",net,hostname)
    newdns = newdnsdata.split(",") if newdnsdata != nil
    newdnssearch = getval("dns-search",net,hostname) 
      
  	if (newip.length != newsubnet.length)		
  		raise ("Incomplete multiple address info in data bag #{$databag_name} #{hostname}. Make sure you have the same number of addresses and netmasks. ip's: #{newip} sub's: #{newsubnet}")		
  	end
  	
  	linfo("Node specific values:")  
  	linfo("  net #{net}")    	
  	linfo("  newip #{newip}")
  	linfo("  newsubnet #{newsubnet}")
  	linfo("  newdfgw #{newdfgw}")
  	linfo("  newdnssearch #{newdnssearch}")
  	$j = 0
  	dns.each do |object|
  		linfo("  newdns[#{$j}] #{newdns[$j]}")
  		$j += 1
  	end 

    #Compare ipaddress and subnets lengths
    refreshIp = false
    if inet.length == newip.length
      $i=0
      newip.each do |i| 
        found = false
        inet.each do |k,a|
          found = true if k == newip[$i] && a["netmask"] == newsubnet[$i]
        end
        refreshIp = true if !found
        $i+=1
      end
    else
      refreshIp = true
    end
    #Compare default gateway
    refreshIp = true if dfgw != newdfgw

    linfo("  refreshIp #{refreshIp}")
    #return

   
    if (newip[0].downcase == "dhcp") && (dhcp == false) 
  		doaction("Changing ip from DHCP=#{dhcp} #{ipaddresses[0]} to DHCP on #{ifname}",\
  				 'netsh interface ip set address "' + ifname + '" dhcp')
  		$nodeUpdated = true
  		sleep(5)
    else
      if newip.length == 1 
        linfo('netsh interface ip set address "' + ifname + \
          '" static "' + \
          newip[0] + \
          '" "' +\
          newsubnet[0]+ '" "' + \
          newdfgw + \
          '"')
  	   doaction("Setting ip from DHCP=#{dhcp} #{ipaddresses[0]} to #{newip[0]} #{newsubnet[0]} #{newdfgw} on #{ifname}",\
                 'netsh interface ip set address "' + ifname + '" static "' + newip[0] + '" "' + newsubnet[0]+ '" "' + newdfgw + '"',\
                 refreshIp && (newip[0].downcase != "dhcp")) 
  		elsif refreshIp
        doaction("Setting ip from DHCP=#{dhcp} #{ipaddresses[0]} to #{newip[0]} #{newsubnet[0]} #{newdfgw} on #{ifname}",\
                 'netsh interface ip set address "' + ifname + '" static "' + newip[0] + '" "' + newsubnet[0]+ '" "' + newdfgw + '"',\
                 (newip[0].downcase != "dhcp"))
  			$i = 1
  			newip.each do |object|												
  				if (newip[$i] != nil) 
            #doaction(infotext,data_cmd,onlyif=true) 
  					doaction("Adding ip #{newip[$i]} #{newsubnet[$i]} on #{ifname}",\
  						'netsh interface ip add address "' + ifname + '" "' + newip[$i] + '" "' + newsubnet[$i]+ '"',\
              (newip[$i].downcase != "dhcp"))
  				end						
  				$i += 1
  			end	   
  		end	   
  			   
  	  $nodeUpdated = true 
    end
  end

  ####################################################################################################
  ### Check and update DNS configuration                                                           ###
  ####################################################################################################
  # Determine which DNS values to use. 
  # We prefer, in order: node specific, environment specific, previous
  # Previous can thus be what DHCP has set it to be

  wd_DomainDNSName = nil
  wd_dns = Array.new
  if node.attribute?($env_att_name)
    # Now, let's get the environment wide DNS settings
    wd_DomainDNSName = node[$env_att_name]['DomainDNSName']
    wd_dns[0] = node[$env_att_name]['DNS1']
    wd_dns[1] = node[$env_att_name]['DNS2']
    wd_dns[2] = node[$env_att_name]['DNS3'] 
  end

  linfo("Environment wide values:")
  linfo("  wd_DomainDNSName #{wd_DomainDNSName}") 
  $i = 0
  wd_dns.each do |object|
    linfo("  wd_dns[#{$i}] #{wd_dns[$i]}")
    $i += 1
  end 

  bestdns = Array.new

  if newdns.count != 0
    linfo("Using DNS values from data bag")
    bestdns = newdns
  else 
    if wd_dns.count != 0
      linfo("Using DNS values from environment")
      bestdns = wd_dns
    else
      if dns.count != 0
        linfo("Using DNS values from machine")
        bestdns = dns
      end
    end
  end    

  linfo("We consider these to be the best DNS's to use:")  
  $i = 0
  bestdns.each do |object|
    linfo("  bestdns[#{$i}] #{bestdns[$i]}")
    $i += 1
  end

  # Get some local info
  mac = macaddress.upcase
  actualdns = r_a('powershell -noprofile -command "(Get-WmiObject Win32_NetworkAdapterConfiguration | where{$_.MacAddress -eq """' + mac + '"""}).DnsServerSearchOrder"')
  actualdnssuffix = registry_get_values("HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\services\\Tcpip\\Parameters").find_all{|item| item[:name] == "SearchList"}[0][:data]
  actualdhcpdata =  r_d('powershell -noprofile -command "(Get-WmiObject Win32_NetworkAdapterConfiguration | where{$_.MacAddress -eq """' + mac + '"""}).DHCPEnabled"')

  if actualdhcpdata != nil
    actualdhcp = actualdhcpdata.downcase
  end

  linfo("Values from actual system:") 
  $i = 0
  dns.each do |object|
    linfo("  actualdns[#{$i}] #{actualdns[$i]}")
    $i += 1
  end
  linfo("  actualdnssuffix #{actualdnssuffix}")
  linfo("  actualdhcp #{actualdhcp}")

  # Compare the best and actual values, and if different set dns. Maximum of three DNS's
  $i = 0
  while $i < 2 do
    if (actualdns[$i] != bestdns[$i]) && (bestdns[$i] != nil)
      updatedns = "true"
    end
    $i += 1
  end

  # Okay, let's set the dns values
  linfo("updatedns #{updatedns}")
  if updatedns == "true"
    $nodeUpdated = true
    $i = 0
    bestdns.each do |object|
      if bestdns[$i] != nil
        if $i == 0 
          doaction("Setting DNS#{$i} on #{ifname} to #{bestdns[$i]}",\
                   'netsh interface ipv4 set dns name="' + ifname + '" source=static address="' + bestdns[$i] + '"')
        else
          doaction("Setting DNS#{$i} on #{ifname} to #{bestdns[$i]} as index #{$i+1}",\
                   'netsh interface ipv4 add dns name="' + ifname + '" address="' + bestdns[$i] + '" index=' + ($i+1).to_s)
        end
        $i += 1
      end
    end 
  end

  # The dns search is system wide, though it will be applied per interface. Last one wins ;)
  registry_key "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\services\\Tcpip\\Parameters" do
    values [{
      :name => "SearchList",
      :type => :string ,
      :data => newdnssearch
      }]
      only_if {newdnssearch != nil && actualdnssuffix != newdnssearch}
      action :create 
  end
  $nodeUpdated = true if newdnssearch != nil && actualdnssuffix != newdnssearch
end
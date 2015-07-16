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

def getnetcount(hostname)  
        case $datatype
                when 1
                        return getnetcount1(hostname)
                when 2
                        return getnetcount2(hostname)
        end
end

def getnet(macaddress,hostname,getfirst="false") 
        case $datatype
                when 1
                        return getnet1(macaddress,hostname,getfirst)
                when 2
                        return getnet2(macaddress,hostname,getfirst)
        end
end

def getnetname(macaddress,hostname,getfirst="false") 
        case $datatype
                when 1
                        return getnet1(macaddress,hostname,getfirst)
                when 2
                        return getnetname2(macaddress,hostname,getfirst)
        end
end

def getval(item,ifname,hostname) 
        case $datatype
                when 1
                        return getval1(item,ifname,hostname) 
                when 2
                        return getval2(item,ifname,hostname) 
        end
end



def linfo(data)
        if $showlog == true
                puts(data)
        else
                Chef::Log.debug(data)
        end
end

def validate_databagitem(bag,item)
    begin 
      rbagitem = data_bag_item(bag,item) 
    rescue Exception => e  
        return false
    end  
    return true
end

class String
  def IPAddr?
    IPAddr.new(self) != nil rescue false
  end
end

def doaction(infotext,data_cmd,onlyif=true)  
    begin
      execute infotext do
        command data_cmd
        action :nothing
        only_if {onlyif}  
      end.run_action(:run)
    rescue Exception => e 
      Chef::Log.error "Failed in executing command. The error was: \n#{e}"
    end
end

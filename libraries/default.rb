#
# Cookbook Name:: windows_network
# Recipe:: default
#
# Copyright 2014, Proxmea BV
#
def getnetcount(hostname)  
        hostname = node["hostname"].downcase
        datab = data_bag_item( $databag_name, hostname)
        datai = datab['interfaces']
        if datai == nil  
                return 0
        end 
        return datai.count
end

def getnet(macaddress,hostname,getfirst="false") 
        macaddress = macaddress.upcase
        macaddress = macaddress
        hostname = node["hostname"].downcase
        datab = data_bag_item( $databag_name, hostname)
        datai = datab['interfaces']
        if datai == nil  
                return nil
        end 
        datai.each do | object|
                data = object['mac']
                if data == macaddress || getfirst == "true"
                        name = object['name']
                        return name
                end
        end 
        return nil
end

def getval(item,ifname,hostname) 
        datab = data_bag_item( $databag_name, hostname) 
        datai = datab['interfaces']
        if datai == nil  
                return nil
        end 
        datai.each do | object|
                if object['name'] == ifname
                        data = object[item] 
                        return data
                end
        end  
        return nil
end 

def linfo(data)
        if $showlog != nil
                Chef::Log.info(data)
        else
                Chef::Log.debug(data)
        end
end
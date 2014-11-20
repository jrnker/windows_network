#
# Cookbook Name:: windows_network
# Recipe:: datatype1.rb
#
# License: Apache license 2
#
# Authors
# Christoffer Järnåker, Proxmea BV, 2014
# Christoffer Järnåker, Schuberg Philis, 2014
#

def getnetcount1(hostname)  
        hostname = node["hostname"].downcase
        return nil if !validate_databagitem($databag_name, hostname)
        datab = data_bag_item( $databag_name, hostname)
        datai = datab['interfaces']
        if datai == nil  
                return 0
        end 
        return datai.count
end

def getnet1(macaddress,hostname,getfirst="false") 
        macaddress = macaddress.upcase 
        hostname = node["hostname"].downcase
        return nil if !validate_databagitem($databag_name, hostname)
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

def getval1(item,ifname,hostname) 
        return nil if !validate_databagitem($databag_name, hostname)
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
#
# Cookbook Name:: windows_network
# Recipe:: retrievedata.rb
#
# License: Apache license 2
#
# Authors
# Christoffer Järnåker, Proxmea BV, 2014
# Christoffer Järnåker, Schuberg Philis, 2014
#


# Run and return data
def r_d(data_cmd, removeCR = true)  
    cmd = Mixlib::ShellOut.new(data_cmd)
    cmd.run_command  
    data = cmd.stdout
    if removeCR == true
      data = data.gsub(/\n/,"").gsub(/\r/,"") 
    end 
    return data 
end

# Run and return array
def r_a(data_cmd) 
    data = r_d(data_cmd,false) 
    if data != nil
      if data.include? "\n"  
        data = data.gsub(/\r/,"").split(/\n/)
      else    
        data2 = Array.new
        data2[0] = data
        data = data2
      end
    end
    return data
end
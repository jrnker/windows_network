#
# Author:: Derek Groh (<derekgroh@gmail.com>)
# Cookbook Name:: windows_network
# Provider:: dnsserver

require 'mixlib/shellout'

action :set do
  if node['os_version'] >= "6.2"
    if exists_2012?
      Chef::Log.info("\"#{new_resource.name}\" found - attempting to set the dns server.")
      new_resource.updated_by_last_action(true)
      if set_2012?
        Chef::Log.info("\"#{new_resource.server_addresses}\" is already set as a DNS Server - nothing to do.")
        new_resource.updated_by_last_action(false)
      else
        cmd = "Set-DnsClientServerAddress"
        cmd << " -InterfaceAlias \"#{new_resource.name}\""
        cmd << " -ResetServerAddresses" if new_resource.reset_server_addresses == true
        cmd << " -ServerAddress \"#{new_resource.server_addresses}\""
        powershell_script "#{new_resource.name}_set_dns_server" do
          code cmd
        end
        Chef::Log.info("\"#{new_resource.server_addresses}\" has been set as the DNS Server.")
        new_resource.updated_by_last_action(true)  
      end
    else
      # This won't happen, because powershell errors out
      Chef::Log.info("\"#{new_resource.name}\" was not found - nothing to do.")
      new_resource.updated_by_last_action(false)
    end
  else
    if exists_2008?
      Chef::Log.info("\"#{new_resource.name}\" found - attempting to set the dns server.")
      new_resource.updated_by_last_action(true)
      if set_2008?
        Chef::Log.info("\"#{new_resource.server_addresses}\" is already set as a DNS Server - nothing to do.")
        new_resource.updated_by_last_action(false)
      else
        cmd = "netsh interface"
        cmd << " #{new_resource.address_family}"
        cmd << " add dnsserver" 
        cmd << " \"#{new_resource.name}\""
        cmd << " #{new_resource.server_addresses}"
        powershell_script "#{new_resource.name}_set_dns_server" do
          code cmd
        end
        Chef::Log.info("\"#{new_resource.server_addresses}\" has been set as the DNS Server.")
        new_resource.updated_by_last_action(true)  
      end
    else
      Chef::Log.info("\"#{new_resource.name}\" was not found - nothing to do.")
      new_resource.updated_by_last_action(false)
    end
  end
end

def exists_2008?
  check = Mixlib::ShellOut.new("powershell.exe -command netsh interface #{new_resource.address_family} show interfaces").run_command
  check.stdout.match(new_resource.name)
end

def exists_2012?
  check = Mixlib::ShellOut.new("powershell.exe -command Get-DnsClientServerAddress -InterfaceAlias \"#{new_resource.name}\" -AddressFamily #{new_resource.address_family} -ErrorAction SilentlyContinue").run_command
  !check.stdout.match("ObjectNotFound")
end

def set_2008?
  check = Mixlib::ShellOut.new("powershell.exe -command netsh interface #{new_resource.address_family} show dns name=\"#{new_resource.name}\"").run_command
  check.stdout.match(new_resource.server_addresses)
end

def set_2012?
  check = Mixlib::ShellOut.new("powershell.exe -command Get-DnsClientServerAddress -InterfaceAlias \"#{new_resource.name}\" -AddressFamily #{new_resource.address_family}").run_command 
  check.stdout.match(new_resource.server_addresses)
end
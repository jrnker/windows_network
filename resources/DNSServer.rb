#
# Author:: Derek Groh (<derekgroh@gmail.com>)
# Cookbook Name:: windows_network
# Resource:: dnsserver

actions :set
default_action :set

attribute :name, :kind_of => String, :name_attribute => true, :required => true
attribute :server_addresses, :kind_of => String, :regex => Resolv::IPv4::Regex
attribute :address_family, :kind_of => String, :default => 'IPv4' 
attribute :reset_server_addresses, :kind_of => [ TrueClass, FalseClass], :default => false
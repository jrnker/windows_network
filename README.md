windows_network chef Cookbook
=======================
This cookbook will configure the network interfaces on Windows 

It looks into a databag for IP information and sets it if it's not set as specified.
It supports two different formats to store the IP configuration, to support logical and the 'udev' (a proprietary) format.

Requirements
------------


This cookbook needs a data bag called 'servers' with an item named as your hostname.
It also uses win_domain for fallback information. 

####Datatype 1 (default)

#####data bag [servers][hostname]
```
{
  "id": "mycomputername",
  "interfaces": [
    {
      "name":     "Local network",
      "mac":      "00:AC:21:BC:F0:E0", 
      "address":  "10.1.0.123",
      "netmask":  "255.255.255.0",
      "gateway":  "10.1.0.1",
      "dns-nameservers": "10.1.0.231,10.111.0.231",
      "dns-search": "mydomain.local"
    }
  ]
}
``` 
or for more than one interface: (here with multipe ip's)

```
{
  "id": "mycomputername",
  "interfaces": [
    {
      "name":     "Local network",
      "mac":      "00:AC:21:BC:F0:E1",  
      "address":  "dhcp"
    },
    {
      "name":     "Local network",
      "mac":      "00:AC:21:BC:F0:E0", 
      "address":  "10.1.0.123,10.1.0.124",
      "netmask":  "255.255.255.0,255.255.255.0",
      "gateway":  "10.1.0.1",
      "dns-nameservers": "10.1.0.231,10.111.0.231",
      "dns-search": "mydomain.local"
    }
  ]
}
```
####Datatype 2 (aka udev)

#####data bag [servers][hostname]
Note that MAC addresses need to be in lowercase

```
{
  "id": "mycomputername",
  "def_gw": "192.168.1.195",
  "net": {
    "eth4": "00:20:56:9a:63:a1",
    "eth0": "00:20:56:9a:13:ee",
    "eth2": "00:20:56:9a:3b:b9",
    "eth1": "00:20:56:9a:40:08"
  },
  "ip": {
    "eth4": "192.168.4.127",
    "eth0": "192.168.3.228",
    "eth2": "192.168.2.228",
    "eth1": "192.168.1.199"
  },
  "netmasks": {
    "eth4": "nil",
    "eth0": "255.255.255.192",
    "eth2": "255.255.255.192",
    "eth1": "255.255.255.192"
  },
  "broadcasts": {
    "eth4": "nil",
    "eth0": "192.168.3.255",
    "eth2": "192.168.2.255",
    "eth1": "192.168.1.255"
  },
  "networks": {
    "eth4": "nil",
    "eth0": "192.168.3.192",
    "eth2": "192.168.2.192",
    "eth1": "192.168.1.192"
  },
  "naming": {
    "build": "00:20:56:9a:63:a1",
    "admin": "00:20:56:9a:13:ee",
    "back": "00:20:56:9a:3b:b9",
    "front": "00:20:56:9a:40:08"
  },
  "dns": {
    "dns1": "192.168.99.121",
    "dns2": "192.168.98.97"
  }
}
```

####Environment (optional)
```
{
  "name": "office",
  "override_attributes": {
    "win_domain": {
      "DNS1": "10.1.0.231",
      "DNS2": "10.1.0.231",
      "DomainDNSName": "mydomain.local"
    }
  }
}
```

Usage
----------

1 Include cookbook in recipe: 
recipe/default.rb

```
include_recipe "windows_network"
```

Optionally override attributes

```
node.override['windows_network']['databag_name'] = "udev" 
node.override['windows_network']['datatype'] = 2 
```
2 Include version in metadata: 
metadata.rb

```
depends 'windows_network', '>= 0.1.0'
``` 

3 Add data bag servers <hostname> as described above section

4 (optional) Add Environment variables under win_domain

Notes
----------
* If there is only one NIC and only one config in the data bag, then this config will be used.
* If there is only one NIC and only one config in the data bag, then the mac entry can be omitted.
* You can specify "dhcp" as address and the NIC will be configure for DHCP.

Todo
----------
* Handle multiple IP addresses per interface
* Handle routes per interface 

Contributing
------------
  1. Fork the repository on Github
  2. Create a named feature branch (i.e. `add-new-recipe`)
  3. Write you change
  4. Write tests for your change (if applicable)
  5. Run the tests, ensuring they all pass
  6. Submit a Pull Request


License and Authors
-------------------
Authors: 

Christoffer Järnåker, Proxmea BV

Christoffer Järnåker, Schuberg Philis, 2014

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

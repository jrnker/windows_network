windows_network Cookbook
=======================
This cookbook will configure the network interfaces on Windows 


Requirements
------------


This cookbook needs a data bag called 'servers' with an item called <hostname>.
It also uses win_domain for fallback information. 


data bag servers <hostname>
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
or
```
{
  "id": "mycomputername",
  "interfaces": [
    {
      "name":     "Local network", 
      "address":  "dhcp"
    }
  ]
}
```

Environment 
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

1. Include cookbook in recipe: 
recipe/default.rb
```
include_recipe "windows_network"
```
2. Include version in metadata: 
metadata.rb
```
depends 'windows_network', '>= 0.1.0'
```
3. Add data bag servers <hostname> as under the requirements section
4. (optional) Add Environment variables under win_domain

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
Authors: Christoffer Järnåker, Proxmea BV

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

# CHANGELOG for windows_network

This file is used to list changes made in each version of sbp_win_ip.

0.3.0
-----
- jrnker - Based on Pull req from rvanderbrugge; implements handling of multiple ip addresses per interface.

0.2.3
-----
- jrnker - Added Ohai relead if network settings changed during run. This means that the node's changed attributes will be reflected in the rest of the run. 

0.2.2
-----
- jrnker - Listened to foodcritic.
		 - Changed the way bestdns is evaluated. Previously it evaluated each DNS server from each source (databag/environment/local setting), but now it uses the best source.
		 - Explored some more if-then scenarios where certain values can be nil and made sure that was handled without exception.
		 - Fixed that datatype 2 could return an empty dns array if the dns entry didn't exist in the data bag. Now it returns nil.
		 - Added Berksfile
		 - If a subnet mask isn't valid then the IP address is also considered invalid.
		 - Also checking default gateway so that it's set right


0.2.1
-----
- jrnker - Wrapping come code into execute statements
		 - Reformatting readme.md 
		 - Fixed default netmask if not specified

0.2.0
-----
- jrnker - Handles multiple (2) datatype formats for the interfaces
		 - Cleaned up code to satisfy foodcritic
		 - Broke out code into several libraries
		 - Fixed spelling error of the 'databag_name' attribute

0.1.1
-----
- jrnker - Implemented handling of IP storage in custom data bag name. 
		   Implemented handling of NIC storage in different format

## 0.1.0:

* Initial release of windows_network

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.

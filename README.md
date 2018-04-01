# collectd-openstack - A collectd plugin to report OpenStack related statistics
=================================

A collectd plugin to send OpenStack related information such as VMs location, falvors, compute nodes and etc. Its written in a way that you can easily extend and add more info based on your need. I expect you to commit your useful changes here, so that everyone can use it.

## REQUIREMENTS

This module has been tested on OpenStack Pike.

## INSTALLATION

To install this module type the following:

````
   perl Makefile.PL
   make
   make test
   make install
````

in `/opt/collectd/etc/collectd.conf`:

````
...
<LoadPlugin "perl">
  Globals true
</LoadPlugin>
...
<Plugin perl>
        BaseName "Collectd::Plugins"
        LoadPlugin "OpenStack"
        <Plugin "openstack">
           MySQLRootPassword "root"
           ConnectUsingDBConnection "true"
	</Plugin>
</Plugin>
...
````

## DEPENDENCIES

OpenStack Pike or Ocata
collectd
perl

## COPYRIGHT AND LICENCE

Collectd-Plugins-OpenStack by Michel Gokan is licensed under a Creative Commons Attribution 4.0 International License.

package Collectd::Plugins::OpenStack;

use strict;
use warnings;
use DBI;

use Collectd qw( :all );

my %CONFIG;

sub openstack_init{
	if(!exists $CONFIG{OpenStackControllerMySQLBindAddress}){
		$CONFIG{OpenStackControllerMySQLBindAddress} = "127.0.0.1";
	}
   
	if(!exists $CONFIG{MySQLRootPassword}){
      $CONFIG{MySQLRootPassword} = "";
	}

	return 1;
}

sub openstack_read
{
	my $v = {
		plugin   => "openstack",
		type	=> "percent",
		time     => time,
	};

	my $myConnection = DBI->connect("DBI:mysql:novadb:$CONFIG{OpenStackControllerMySQLBindAddress}", "root", "$CONFIG{MySQLRootPassword}") or die "Unable to connect: $DBI::errstr\n";


	my $columns_to_select = "vcpus,memory_mb,vcpus_used,memory_mb_used,local_gb_used,cpu_info,disk_available_least,free_ram_mb,free_disk_gb,running_vms,hypervisor_hostname,deleted,host_ip,supported_instances,ram_allocation_ratio,cpu_allocation_ratio,uuid,disk_allocation_ratio,mapped";

   my $query = $myConnection->prepare("select host,$columns_to_select from compute_nodes");
   my $result = $query->execute();

   my @columns = split /,/, $columns_to_select;

	while(my @row = $result->fetchrow_array()){
		my $counter = 0;
		foreach my $column (@columns) {
                    $v->{'plugin_instance'} = "$row[0]",
                    $v->{'type_instance'} = "$column",
                    $v->{'values'} = [ $row[$counter++] ],
                    plugin_dispatch_values($v);
		}
	}

	$result->finish();
	$result->disconnect();
	
	return 1;
}

sub openstack_config
{
	my @config = @{ $_[0]->{children} };

	foreach(@config) {
		my $okey = $_->{key}; # for error messages
		my $key = lc $okey;
		my @values = $_->{values};

		my $value = $_->{values}->[0];
		plugin_log(LOG_NOTICE, "TOP CONF - Inside foreach $key / $value");
	
		if ($key eq "openstackcontrollermysqlbindaddress") {
			$CONFIG{OpenStackControllerMySQLBindAddress} = $value;
		} elsif ($key eq "mysqlrootpassword") {
			$CONFIG{MySQLRootPassword} = $value;
		}
	}

	return 1;
}

plugin_register(TYPE_INIT, "openstack", "openstack_init");
plugin_register (TYPE_READ, "openstack", "openstack_read");
plugin_register (TYPE_CONFIG, "openstack", "openstack_config");

1;

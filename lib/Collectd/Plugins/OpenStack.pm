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
      plugin => "openstack",
      type => "gauge",
      time => time,
   };

   my $nova_connection = DBI->connect("DBI:mysql:novadb:$CONFIG{OpenStackControllerMySQLBindAddress}", "root", "$CONFIG{MySQLRootPassword}") or die "Unable to connect: $DBI::errstr\n";

   my $compute_nodes_columns = "id,vcpus,memory_mb,vcpus_used,memory_mb_used,local_gb_used,disk_available_least,free_ram_mb,free_disk_gb,running_vms,deleted,ram_allocation_ratio,cpu_allocation_ratio,disk_allocation_ratio,mapped";
   my $vms_columns = "id,host_id,power_state,memory_mb,vcpus,root_gb";

   my $compute_nodes_query = $nova_connection->prepare("select host,$compute_nodes_columns from compute_nodes");
   my $compute_nodes_query_result = $compute_nodes_query->execute();
   
   my $vms_query = $nova_connection->prepare("select i.hostname,i.id,c.id,i.power_state,i.memory_mb,i.vcpus,i.root_gb from instances as i inner join compute_nodes as c on i.host=c.host where i.deleted=0;");
   my $vms_query_result = $vms_query->execute();

   my @compute_nodes_columns_array = split /,/, $compute_nodes_columns;
   my @vms_columns_array = split /,/, $vms_columns;

   while(my @row = $compute_nodes_query->fetchrow_array){
      my $counter = 1;
  
      foreach my $column (@compute_nodes_columns_array) {    
         $v->{'plugin'} = "openstack-compute-nodes",	
         $v->{'plugin_instance'} = "$row[0]",	
         $v->{'type_instance'} = "$column",
         $v->{'values'} = [ $row[$counter++] ],
         plugin_dispatch_values($v);
      }
   }

   while(my @row = $vms_query->fetchrow_array){
      my $counter = 1;
  
      foreach my $column (@vms_columns_array) {    
         $v->{'plugin'} = "openstack-vms",	
         $v->{'plugin_instance'} = "$row[0]",	
         $v->{'type_instance'} = "$column",
         $v->{'values'} = [ $row[$counter++] ],
         plugin_dispatch_values($v);
      }
   }

   $compute_nodes_query->finish();
   $vms_query->finish();
   $nova_connection->disconnect;
	
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
      plugin_log(LOG_NOTICE, "OpenStack CONF - Inside foreach $key / $value");
	
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

#
# === Class: profile::solr::server
#
# Setup simple Solr Server
#
# === Parameters
#
# [*cores*]
#   List of cores (passed to solr::cores)
#   (String/Array/Hash) Defaults to {}
#
# [*client_ips*]
#   Static list of client IPs that can connect to solr (in lieu of exported resources)
#   (list) Default []
#
# [*port*]
#   Solr (Jetty) Port override
#   (int) Default '8983'
#
# [*use_swap_file*]
#   Whether or not to use a swap file
#   (Boolean) Default true
#
# [*core_defaults*]
#   default options passed to solr::core
#   (Hash) Default {}
#
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::solr::server':
#           use_swap_file  => true,
#   }
#
# [*Hiera YAML*]
#   profile::solr::server::use_swap_file: true
#
class profile::solr::server (
  $cores = {},
  $client_ips = [],
  $port = $profile::solr::port,
  $use_swap_file = true,
  $core_defaults = {},
) inherits profile::solr {

  #validate_hash($cores) # (or array or list) ?
  validate_array($client_ips)
  #validate_int($port)
  validate_bool($use_swap_file)

  # Java is needed
  include ::java

  # SWAP!?
  if $use_swap_file {
    include ::swap_file
  }

  # Solr Server
  # Some defaults, simple one host, all in one install
  class { '::solr':
    solr_port => $port,
  }

  # Create defined cores
  if is_hash($cores) {
    create_resources('solr::core', $cores, $core_defaults)
  } else {
    ensure_resource('solr::core', $cores, $core_defaults)
  }

  # Create exported resource cores
  if str2bool($::settings::storeconfigs) {
    Solr::Core <<| tag == "solr_${::environment}_${::client}_${::app_tier}_${::app_name}_core" |>>
  }

  # Firewall
  if str2bool($::settings::storeconfigs) {
    # Let other systems connect outbound to us.
    @@firewall { "200 OUTPUT allow solr access at ${::ipaddress}:${port}":
      dport       => $port,
      proto       => 'tcp',
      action      => 'accept',
      chain       => 'OUTPUT',
      destination => $::ipaddress,
      tag         => "fw_${trusted['extensions']['pp_environment']}_${::client}_${trusted['extensions']['pp_role']}_${trusted['extensions']['pp_application']}_solr_out_to_solr_server",
    }
    # Allow inbound connections.
    Firewall <<| tag == "fw_${trusted['extensions']['pp_environment']}_${::client}_${trusted['extensions']['pp_role']}_${trusted['extensions']['pp_application']}_solr_in_from_clients" |>>

    # hosts entry for SOLR CLIENT to find SOLR SERVER
    @@host { $::fqdn:
      ensure       => present,
      host_aliases => 'solr.puppet',
      comment      => 'profile::solr::sever',
      ip           => $::ipaddress,
      tag          => "host_${trusted['extensions']['pp_environment']}_${::client}_${trusted['extensions']['pp_role']}_${trusted['extensions']['pp_application']}_solr_server",
    }
  }

  # Manual firewall rule overrides
  $fw_client_ips = suffix($client_ips, '||SOLR-Access')
  ensure_resource(profile::firewall::fwrule, $fw_client_ips, {
    direction => 'INPUT',
    port      => $port,
    proto     => 'tcp',
  })

  sensu::check {'solr running':
    handlers => [ 'default' ],
    interval => 180,
    command  => '/etc/sensu/plugins/check-process.rb -p "-Dsolr.solr.home=" -c1 -w1',
  }

  # Get a "list" of cores for monitoring
  if is_hash($cores) {
    $monitor_cores = keys($cores)
  } else {
    $monitor_cores = $cores
  }

  ensure_resource(profile::solr::sensu_check_solr_core, $monitor_cores, {
    server => $::ipaddress,
    port   => $port,
  })


#  # Admin Firewall Rules (currently only accepting hard coded rules)
#  ensure_resource(profile::firewall::fwrule, any2array($admin_ips), {
#    direction => 'INPUT',
#    port      => $port,
#    proto     => 'tcp',
#  })

}

#
# === Class: profile::solr::client
#
# Setup simple Solr Server
#
# === Parameters
#
# - server_ips - IP addresses that can (statically) access solr port (list) - default []
# - port - Port(s) that will run Solr Server Search (currently only used for firewall rules) - Default: 8983
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::solr::client':
#           use_swap_file  => true,
#   }
#
# [*Hiera YAML*]
#   profile::solr::client::use_swap_file: true
#
class profile::solr::client (
  $server_ips = [],
  $port = $profile::solr::port,
) inherits profile::solr {

  validate_array($server_ips)
  #validate_int($port)

  # Java is needed for SOLR (is it needed for the client?)
  #include ::java

  # Firewall
  if str2bool($::settings::storeconfigs) {
    # Let other systems connect outbound to us.
    @@firewall { "200 INPUT allow solr access from ${::ipaddress} to ${port}":
      dport  => $port,
      proto  => 'tcp',
      action => 'accept',
      chain  => 'INPUT',
      source => $::ipaddress,
      tag    => "fw_${trusted['extensions']['pp_environment']}_${::client}_${trusted['extensions']['pp_application']}_solr_in_from_clients",
    }
    # Allow inbound connections.
    Firewall <<| tag == "fw_${trusted['extensions']['pp_environment']}_${::client}_${trusted['extensions']['pp_application']}_solr_out_to_solr_server" |>>

    # Pick up the hosts file entry that was left for us.
    Host <<| tag == "host_${trusted['extensions']['pp_environment']}_${::client}_${trusted['extensions']['pp_application']}_solr_server" |>>
  }

  # Manual firewall rule overrides
  $fw_server_ips = suffix($server_ips, '||SOLR-Server-Access')
  ensure_resource(profile::firewall::fwrule, $fw_server_ips, {
    direction => 'OUTPUT',
    port      => $port,
    proto     => 'tcp',
  })

#  # Admin Firewall Rules (currently only accepting hard coded rules)
#  ensure_resource(profile::firewall::fwrule, any2array($admin_ips), {
#    direction => 'INPUT',
#    port      => $port,
#    proto     => 'tcp',
#  })

}

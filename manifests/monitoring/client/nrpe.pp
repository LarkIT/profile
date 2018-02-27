# === Class: profile::monitoring::client::nrpe
#
# Setup / Install NRPE Client software
#
# === Parameters
#
# NOTE: For paramters/checks see ghoneycutt/nrpe class, use Hiera!
#
# === Sample invocation
#
# PRIVATE - Please use the profile::monitoring::client instead
#
# [*Puppet*]
#   #N/A
#
# [*Hiera YAML*]
#   #N/A
#
class profile::monitoring::client::nrpe (
  $port = 5666
) {

  # Monitoring Rule Firewalls - are a bit reversed because the "server" connects to the "clients"
  # NOTE: DO NOT COPY THIS EXAMPLE FOR OTHER SERVICES
  if str2bool($::settings::storeconfigs) {
    # Export to database server(s)
    @@firewall { "100 OUTPUT allow Monitoring nrpe (tcp/${port}) to ${::ipaddress}":
      dport       => $port,
      proto       => 'tcp',
      action      => 'accept',
      chain       => 'OUTPUT',
      destination => $::ipaddress,
      tag         => "monitoring_client_nrpe_${::profile::monitoring::monitoring_tag}",
    }

    # Pick up the rules that were left for us.
    Firewall <<| tag == "monitoring_server_nrpe_${::profile::monitoring::monitoring_tag}" |>>
  }

  # Manual firewall rule overrides
  if $::profile::monitoring::client::servers {
    $fw_servers = suffix(any2array($::profile::monitoring::client::servers), '||MonitoringServers')
    ensure_resource(profile::firewall::fwrule, $fw_servers, {
      port      => $port,
      direction => 'INPUT',
    })
  }

  # Add 127.0.0.1 to the list of allowed_hosts
  $allowed_hosts=flatten(['127.0.0.1', $profile::monitoring::client::servers])

  class { '::nrpe':
    allowed_hosts => $allowed_hosts,
    server_port   => $profile::monitoring::client::port,
  }

}

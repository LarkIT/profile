#
# === Class: profile::database::server
#
# Setup Database Server
#
# === Parameters
#
# [*type*]
#   Type of database server to install.
#   (String) Defaults to 'mysql'
#     Acceptable Values:
#       * mysql
#       * postgresql
#
# [*app_servers*]
#   A list of app servers for firewall purposes (in lieu of exported resources)
#   (String or Array) Defaults to []
#
# [*port*]
#   Database Port override (will select a proper default based on $type)
#   (String) Default undef
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::database::server':
#     $type    => 'mysql',
#     $app_servers => '10.1.2.3',
#   }
#
# [*Hiera YAML*]
#   profile::database::server::type: mysql
#   profile::database::server::app_servers: '10.1.2.3'
#
class profile::database::server (
  $type          = $profile::database::type,
  $app_servers   = [],
  $port          = $profile::database::port,
) inherits profile::database {

  # Validate
  validate_string($type)
  if is_string($app_servers) {
    validate_string($app_servers)
  } else {
    validate_array($app_servers)
  }

  case $type {
    'mysql': {
      include ::profile::database::server::mysql
    }
    'postgresql': {
      include ::profile::database::server::postgresql
    }
    default: {
      fail('Unacceptable value at profile::database::server::type')
    }
  }

  if str2bool($::settings::storeconfigs) {
    # Let other systems connect outbound to us.
    @@firewall { "200 OUTPUT allow app to database server tcp at ${::ipaddress}:${port}":
      dport       => $port,
      proto       => 'tcp',
      action      => 'accept',
      chain       => 'OUTPUT',
      destination => $::ipaddress,
      tag         => "fw_${::environment}_${::client}_${::app_tier}_${::app_name}_out_app_to_db",
    }

    # Allow inbound connections.
    Firewall <<| tag == "fw_${::environment}_${::client}_${::app_tier}_${::app_name}_in_app_to_db" |>>

    # hosts entry for DB CLIENT to find DB SERVER
    @@host { $::fqdn:
      ensure       => present,
      host_aliases => 'db.puppet',
      comment      => 'profile::database::server',
      ip           => $::ipaddress,
      tag          => "host_${::environment}_${::client}_${::app_tier}_${::app_name}_dbserver",
    }
  }

  # Manual firewall rule overrides
  any2array($app_servers).each | String $ip | {
    firewall { "400 INPUT - Database Connectivity from ${ip} on ${port} (tcp)":
      dport  => $port,
      proto  => 'tcp',
      action => 'accept',
      chain  => 'INPUT',
      source => $ip,
    }
  }

}

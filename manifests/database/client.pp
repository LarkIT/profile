#
# === Class: profile::database::client
#
# Setup Database Client
#
# === Parameters
#
# [*type*]
#   Type of database client to install.
#   (String) Defaults to 'mysql'
#     Acceptable Values:
#       * mysql
#       * postgresql
#
# [*db_servers*]
#   A list of database servers for firewall purposes (in lieu of exported resources)
#   (String or Array) Defaults to undef.
#
# [*port*]
#   Database Port override (will select a proper default based on $type)
#   (String) Default undef
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::database::client':
#     $type    => 'mysql',
#     $db_servers => '10.1.2.3',
#   }
#
# [*Hiera YAML*]
#   profile::database::client::type: mysql
#   profile::database::client::db_servers: '10.1.2.3'
#
class profile::database::client (
  $type       = $profile::database::type,
  $db_servers = [],
  $port       = $profile::database::port,
) inherits profile::database {

  # Validate
  validate_string($type)
  if is_string($db_servers) {
    validate_string($db_servers)
  } else {
    validate_array($db_servers)
  }

  case $type {
    'mysql': {
      include ::profile::database::client::mysql
    }
    'postgresql': {
      include ::profile::database::client::postgresql
    }
    default: {
      fail('Unacceptable value at profile::database::client::type')
    }
  }

  if str2bool($::settings::storeconfigs) {
    # Export to database server(s)
    @@firewall { "100 INPUT allow DB tcp inbound from app at ${::ipaddress}":
      dport    => $port,
      proto    => 'tcp',
      action   => 'accept',
      chain    => 'INPUT',
      source   => $::ipaddress,
      tag      => "fw_${::environment}_${::client}_${::app_tier}_${::app_name}_in_app_to_db",
      provider => 'iptables',
    }

    # Pick up the rules that were left for us.
    Firewall <<| tag == "fw_${::environment}_${::client}_${::app_tier}_${::app_name}_out_app_to_db" |>>

    # Pick up the hosts file entry that was left for us.
    Host <<| tag == "host_${::environment}_${::client}_${::app_tier}_${::app_name}_dbserver" |>>
}

  # Manual firewall rule overrides
  any2array($db_servers).each | String $ip | {
    firewall { "300 OUTPUT - Database Connectivity to ${ip} on ${port} (tcp)":
      dport       => $port,
      proto       => 'tcp',
      action      => 'accept',
      chain       => 'OUTPUT',
      destination => $ip,


    }
  }
}


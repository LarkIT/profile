# PRIVATE CLASS
#
# === Class: profile::database::client::postgresql
#
# Setup Postgresql client.
#
# === Parameters
#
# [*install_dev*]
#   Install Postgres Devel package
#   (Boolean) Defaults to true
#
#
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::database::client:::postgresql':
#   }
#
# [*Hiera YAML*]
#   profile::database::client::::postgresql: '92'
#
class profile::database::client::postgresql (
  $install_dev = true,
) inherits profile::database {

  # Validate
  validate_bool($install_dev)

  include ::postgresql::globals
  include ::postgresql::client

  if $install_dev {
    include ::postgresql::lib::devel
  }

  if str2bool($::settings::storeconfigs) {
    @@postgresql::server::pg_hba_rule { "allow access from ${::ipaddress}":
      description => "allow access from ${::ipaddress}",
      type        => 'host',
      database    => 'all',
      user        => 'all',
      address     => "${::ipaddress} 255.255.255.255",
      auth_method => 'md5',
      order       => '002',
      tag         => "ptag_hba_${::environment}_${::app_name}_${::client}_${::app_tier}_in_app_to_db",
    }
  }
}

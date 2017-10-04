#
# === Class: profile::database::server::mysql
#
# Setup / Install MySQL Server software
#
# === Parameters
#
# [*databases*]
#   Database Hash to create databases (passed to mysql::db)
#   (Hash) Defaults to profile::databases::databases
#
# [*create_db_roles*]
#   NOT YET IMPLEMENTED - would be to create accounts with "create" access
#
# [*default_hostmask*]
#   Users host mask (user@HOSTMASK)
#   (String) Defaults to '%'
#
# [*backups_enabled*]
#   Whether or not to enable mysql backups
#   (Boolean) Defaults to false
#
# [*monitoring_enabled*]
#   Whether or not to enable mysql monitoring
#   (Boolean) Defaults to false
#
# [*tuning_packages*]
#   List of packages to install for tuning
#   (List) Defaults to innotop, mytop, mysqltuner
#
# NOTE: For Server parameters see puppetlabs/mysql class
#
# === Sample invocation
#
# [*Puppet*]
#   include profile::database::server::mysql
#
# [*Hiera YAML*]
#   profile::database::server::mysql::backups_enabled: true
#
class profile::database::server::mysql (
  $databases = $profile::database::databases,
  $create_db_roles = {},
  $default_hostmask = '%',
  $backups_enabled = false,
  $monitoring_enabled = false,
  $tuning_packages = [ 'innotop', 'mytop', 'mysqltuner' ]
) inherits profile::database {

  # Validate
  validate_hash($databases)
  validate_hash($create_db_roles)
  validate_string($default_hostmask)
  #validate_boolean($backups_enabled)
  #validate_boolean($monitoring_enabled)
  validate_array($tuning_packages)

  ## TODO: create_db_roles not implemented

  include ::mysql::client
  include ::mysql::server
  include ::mysql::server::account_security
  include ::mysql::bindings

  if $monitoring_enabled {
    include ::mysql::server::monitor
  }

  if $backups_enabled {
    include ::mysql::server::backup
  }

  if str2bool($::settings::storeconfigs) {
    Mysql::Db <<| tag == "${::environment}_${::client}_${::app_tier}" |>>
  }

  # Tuning Packages
  ensure_packages($tuning_packages)

  create_resources('mysql::db', $databases, {
    host  => $default_hostmask,
    grant => ['ALL'],
  })

}

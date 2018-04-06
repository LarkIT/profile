#
# Class: profile::solr::sensu_check_solr_core
# Purpose: Manage Sensu Checks for a list of solr cores
#
# Example:
#  # Monitor Cores
#
define profile::solr::sensu_check_solr_core (
  $core     = $name,
  $server   = $::ipaddress,
  $port     = 8983,
  $interval = 300,
  $handlers = '[default]',
) {

  validate_string($core)
  validate_string($server)
  #validate_integer($port)
  #validate_integer($interval)
  validate_string($handlers)

  #   ssh_authorized_key { "${user}@${::fqdn}-${name}":
  #     ensure  => present,
  #     key     => $name,
  #     user    => $user,
  #     type    => rsa,
  #     require => File[$ssh_authorized_keys]
  #   }
}

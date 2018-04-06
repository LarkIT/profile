#
# Class: profile::monit
# Purpose: Setup a monit process monitoring service
#
# === Parameters
#
# [*admin_ips*]
#   list of admin_ips (allowed to access interface)
#   (Array) Defaults to profile::firewall::admin_ips
#   NOTE: Set to undef to allow access from any IP
#
# [*port*]
#   Web Admin Port for monit (also see enable_webadmin)
#   (String) Default 2182
#
# [*enable_webadmin*]
#   Enable the Web Admin interface in Monit
#   (Boolean) Default true
#
# [*checks*]
#   Manually specified Monit checks (will also realize exported resources)
#     (see https://github.com/echoes-tech/puppet-monit#add-a-check)
#   (Hash) Default {}
#
# Status: Beta
#
class profile::monit (
  $admin_ips       = [], # $profile::firewall::admin_ips
  $port            = 2812,
  $enable_webadmin = true,
  $checks          = {},
) {

  validate_array($admin_ips)
  #validate_integer($port)
  validate_bool($enable_webadmin)
  validate_hash($checks)

  # Specify all monit specific arguments in HIERA
  class { '::monit':
    httpd      => $enable_webadmin,
    httpd_port => $port,
  }

  # Create manually defined resources
  create_resources( '::monit::check', $checks )

  if str2bool($::settings::storeconfigs) {
    Monit::Check <<| tag == "${::environment}_${::client}_${::app_tier}_monit" |>>
  }
}

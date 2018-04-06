#
# Class name: profile::newrelic.pp
# Purpose: Setup NewRelic Server Monitoring if license_key is provided
#  ... Log message if license key is not provided.
#
# === Parameters
#
# [*license_key*]
#   New Relic License Key
#   (String) Default hiera('newrelic::server::linux::newrelic_license_key', undef)
#        NOTE: Will use the key from the ::newrelic module default hiera key
# [*php_agent*]
#    Install PHP Agent?
#    (Boolean) Default: false
#
# === Sample invocation
#
# [*Puppet*]
#   # DON'T DO THIS! USE HIERA
#   class { 'profile::newrelic':
#     $license_key    => 'blahblahblah',
#   }
#
# [*Hiera YAML*]
#   profile::newrelic::license_key: 'blahblahbahblahblah'
#
class profile::newrelic (
  $license_key = hiera('newrelic::server::linux::newrelic_license_key', undef),
  $php_agent = false,
) {

  include repos::newrelic

  if ( $license_key ) {
    # Install Newrelic Server
    class { '::newrelic::server::linux':
      newrelic_license_key => $license_key,
    }

    if $php_agent and defined(Class['apache']) {
      if str2bool($::selinux) {
        package { 'newrelic_httpd-selinux': }
      }

      class { '::newrelic::agent::php':
        newrelic_daemon_port => '/var/run/newrelic/.newrelic.sock',
        newrelic_license_key => $license_key,
      }

      Class['newrelic::agent::php'] ~> Class['apache']
    }

  } elsif ($license_key == 'DISABLE') {
    # DO NOTHING, SILENTLY
  } else {
    notify { 'MissingNewRelicLicenseKey':
      message =>  'Please provide a profile::newrelic::license_key to enable NewRelic',
    }
  }

  # Should there be outbound firewall rules to newrelic?
}

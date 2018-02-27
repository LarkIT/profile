#
# Class name: profile::apacheweb::php
# Purpose: Setup PHP for Apache web server.
#
class profile::apacheweb::php (
  $php_package = undef,
  $php_path    = undef,
) {

  include ::profile::apacheweb

  class {'::apache::mod::php':
    package_name => $php_package,
    path         => $php_path,
  }

  if defined(Class['newrelic']) and $::newrelic::server::linux::newrelic_license_key {
    if hiera('selinux_enabled',false) {
      package { 'newrelic_httpd-selinux': }
    }

    class { '::newrelic::agent::php':
      newrelic_daemon_port => '/var/run/newrelic/.newrelic.sock',
      newrelic_license_key => $::newrelic::server::linux::newrelic_license_key,
    }

    Class['newrelic::agent::php'] ~> Class['apache']
  }

}

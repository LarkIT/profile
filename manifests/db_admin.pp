#
# Class name: profile::db_admin
# Purpose: Setup phpMyAdmin and/or phpPgAdmin.
#
# === Parameters
#
# [*phpmyadmin*]
#   Whether or not phpMyAdmin should be installed
#   Boolean.  Default: false
#
# [*phppgadmin*]
#   Whether or not phpPgAdmin should be installed
#   Boolean.  Default: false
#
# [*port*]
#   Port for apache to run on
#   Integer.  Default: 80 for ssl == false, 443 for ssl == true
#
# [*ssl*]
#   Whether or not SSL should be enabled for the vhost
#   Boolean.  Default: false
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::db_admin':
#     phpmyadmin => true,
#     phppgadmin => true,
#   }
#
#
class profile::db_admin (
  $phpmyadmin  = false,
  $phppgadmin  = false,
  $port        = undef,
  $vhost       = $::fqdn,
  $ssl         = false,
  $letsencrypt = false,
  $admin_ips   = $profile::firewall::admin_ips,
) {

  include ::apache
  include ::apache::mod::php

  if $letsencrypt and !$ssl {
    fail('profile::db_admin: ssl is required to use letsencrypt')
  }

  if $letsencrypt and $ssl {
    include ::profile::letsencrypt
    $_ssl_cert = "/etc/letsencrypt/live/${::fqdn}/cert.pem"
    $_ssl_key = "/etc/letsencrypt/live/${::fqdn}/privkey.pem"
    $_ssl_chain = "/etc/letsencrypt/live/${::fqdn}/chain.pem"

    ## NOTE: We need to deal with port 443 not being public
  }
  # We do not allow ssl cert/key/chain to be specified currently

  # need epel
  if $phpmyadmin {
    class { '::phpmyadmin': }
    $_my_aliases = [
      {
        alias => '/phpmyadmin',
        path  => '/usr/share/phpMyAdmin'
      }, {
        alias => '/phpMyAdmin',
        path  => '/usr/share/phpMyAdmin'
      },
    ]

    $_my_dirs = [
      {
        'path' => '/usr/share/phpMyAdmin/',
        'allow' => 'from all',
      }, {
        'path' => '/usr/share/phpMyAdmin/setup/',
        'deny' => 'from all',
        'allow' => 'from none',
      }, {
        'path' => '/usr/share/phpMyAdmin/libraries/',
        'deny' => 'from all',
        'allow' => 'from none',
      },
    ]
  } else {
    $_my_aliases = []
    $_my_dirs = {}
  }

  if $phppgadmin {
    class { '::phppgadmin': }
    $_pg_aliases = [
      {
        alias => '/phpPgAdmin',
        path  => '/usr/share/phpPgAdmin'
      }, {
        alias => '/phppgadmin',
        path  => '/usr/share/phpPgAdmin'
      },
    ]
  } else {
    $_pg_aliases = []
    $_pg_dirs = []
  }

  $_aliases = concat($_my_aliases, $_pg_aliases)

  if $port {
    $_port = $port
  } else {
    $_port = $ssl ? {
      true    => 443,
      default => 80
    }
  }

  if !defined(Selboolean['httpd_can_network_connect_db']) {
    selboolean { 'httpd_can_network_connect_db':
      persistent => true,
      value      => on,
    }
  }

  if $phpmyadmin or $phppgadmin {
    apache::vhost { $vhost:
      docroot     => '/var/www/html',
      port        => $_port,
      aliases     => $_aliases,
      directories => $_my_dirs,
      ssl         => $ssl,
      ssl_cert    => $_ssl_cert,
      ssl_key     => $_ssl_key,
      ssl_chain   => $_ssl_chain,
    }

    # Admin Firewall Rules (currently only accepting hard coded rules)
    $fw_admin_ips = suffix(any2array($admin_ips), '||admin-db_admin')
    ensure_resource(profile::firewall::fwrule, $fw_admin_ips, {
      direction => 'INPUT',
      port      => $_port,
      proto     => 'tcp',
    })
  }


}

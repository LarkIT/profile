#
# Class: profile::jenkins
# Purpose: Setup a Jenkins server
#
# === Parameters
#
# [*admin_ips*]
#   list of admin_ips (allowed to access jenkins)
#   (Array) Defaults to profile::firewall::admin_ips
#   NOTE: Set to undef to allow access from any IP
#
# [*port*]
#   Jenkins Port (for firewall only at this point)
#   (String) Default is 443 if use_vhost and ssl, 80 if use_vhost and !ssl, and 8080 if !use_vhost
#
# [*manage_security*]
#   Manage Jenkins Security (not really very good at the moment)
#   (Boolean) Default false
#
# [*use_vhost*]
#   Setup Apache vHost to proxy to Jenkins (good idea)
#   (Boolean) Default false
#
#
# [*ssl*]
#   Enable/Require SSL for the Apache vHost
#   (Boolean) Default false
#
# [*letsencrypt*]
#   Setup a *FREE* (for outside facing servers) LetsEncrypt SSL Certificate
#   (Boolean) Default false
#
# [*proxy_vhost*]
#   What hostname to use for the jenkins vhost.
#   (String) Default $::fqdn
#
#
#
# Status: Beta
#
class profile::jenkins (
  $admin_ips       = $::profile::firewall::admin_ips,
  $port            = undef,
  $manage_security = false,
  $use_vhost       = false,
  $ssl             = false,
  $letsencrypt     = false,
  $proxy_vhost     = $::fqdn,
) {

  include ::repos::jenkins

  # Specify all jenkins specific arguments in HIERA
  include ::jenkins
  include ::git

  if $letsencrypt {
    include ::profile::letsencrypt
  }

  if $manage_security {
    file { '/var/lib/jenkins/config.xml':
      ensure  => file,
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0700',
      source  => "puppet:///modules/${module_name}/profile/jenkins/config.xml",
      require => Class[ '::jenkins' ],
    }

    file { '/etc/pam.d/jenkins':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => "puppet:///modules/${module_name}/profile/jenkins/pam",
    }
  }

  if $ssl and !$use_vhost {
    fail('profile::jenkins: use_vhost is required to use ssl')
  }

  if $port {
    $_port = $port
  } else {
    $_port = $ssl ? {
      true    => 443,
      default => $use_vhost ? {
        true    => 80,
        default => 8080
      }
    }
  }

  if $use_vhost {
    include ::apache

    if $ssl {
      $_headers = ['set X-Forwarded-Proto "https"',
                    "set X-Forwarded-Port '${_port}'",
                  ]
    } else {
      $_headers = undef
    }

    if !defined(Selboolean['httpd_can_network_connect']) {
      selboolean { 'httpd_can_network_connect':
        persistent => true,
        value      => on,
      }
    }

    apache::vhost { 'jenkins':
      docroot             => '/var/www/html',
      manage_docroot      => false,
      ssl                 => $ssl,
      port                => $_port,
      servername          => $proxy_vhost,
      request_headers     => $_headers,
      proxy_preserve_host => true,
      proxy_pass          => [
        {
          path => '/',
          url  => 'http://127.0.0.1:8080/',
        },
      ],
    }
  }

  firewall { '200 OUTPUT SSH ports tcp':
    dport  => [ '22' ],
    proto  => 'tcp',
    action => 'accept',
    chain  => 'OUTPUT',
  }

  firewall { '200 OUTPUT SSH ports tcp IPv6':
    dport    => [ '22' ],
    proto    => 'tcp',
    action   => 'accept',
    chain    => 'OUTPUT',
    provider => 'ip6tables',
  }

  # Admin Firewall Rules (currently only accepting hard coded rules)
  if $admin_ips {
    $fw_admin_ips = suffix(any2array($admin_ips), '||JENKINS')
    ensure_resource(profile::firewall::fwrule, $fw_admin_ips, {
      direction => 'INPUT',
      port      => $_port,
      proto     => 'tcp',
    })
  }
}

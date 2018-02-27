#
# === Class: profile::webapps::wordpress
#
class profile::webapps::wordpress (
  $environment,
  $application,
  $github_oauth = undef,
  $letsencrypt  = false,
) {

  validate_string($environment)
  validate_string($application)

  include ::php
  include ::profile::apacheweb::php
  include ::profile::webapp
  include ::profile::database::client

  if $letsencrypt {
    include ::profile::letsencrypt
  }

  $_base = "/web/${application}/${environment}/public_html"

  selinux::fcontext {$_base:
    pathname => "${_base}(/.*)?",
    context  => 'httpd_sys_content_t',
  }

  selinux::fcontext {"${_base}/wp-content/uploads":
    pathname => "${_base}/wp-content/uploads(/.*)?",
    context  => 'httpd_sys_rw_content_t',
  }

  # RW dirs used by wordpress
  file { "${_base}/wp-content/uploads":
    ensure  => directory,
    owner   => $application,
    group   => 'apache',
    mode    => '0775',
    seltype => 'httpd_sys_rw_content_t',
    require => Selinux::Fcontext["${_base}/wp-content/uploads"],
  }

  if !defined(Selboolean['httpd_can_network_connect_db']) {
    selboolean { 'httpd_can_network_connect_db':
      persistent => true,
      value      => on,
    }
  }

  logrotate::rule { 'wp_logs':
    path         => "${_base}/wp-content/*.log",
    rotate       => 5,
    rotate_every => 'week',
    compress     => true,
    copytruncate => true,
    missingok    => true,
    ifempty      => false,
    su           => true,
    su_owner     => $application,
    su_group     => $application,
  }
}

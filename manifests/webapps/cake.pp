#
# === Class: profile::webapps::cake
#
class profile::webapps::cake (
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
    pathspec => "${_base}(/.*)?",
    seltype  => 'httpd_sys_content_t',
  }

  selinux::fcontext {"${_base}/logs":
    pathspec => "${_base}/logs(/.*)?",
    seltype  => 'httpd_sys_rw_content_t',
  }

  selinux::fcontext {"${_base}/tmp":
    pathspec => "${_base}/tmp(/.*)?",
    seltype  => 'httpd_sys_rw_content_t',
  }

  # RW dirs used by cake
  file { ["${_base}/logs", "${_base}/tmp"]:
    ensure  => directory,
    owner   => $application,
    group   => 'apache',
    mode    => '0775',
    seltype => 'httpd_sys_rw_content_t',
    require => [Selinux::Fcontext["${_base}/logs"], Selinux::Fcontext["${_base}/tmp"]],
  }

  if !defined(Selboolean['httpd_can_network_connect_db']) {
    selboolean { 'httpd_can_network_connect_db':
      persistent => true,
      value      => on,
    }
  }

  logrotate::rule { 'cake_logs':
    path         => "${_base}/logs/*.log",
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

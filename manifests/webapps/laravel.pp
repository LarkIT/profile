#
# === Class: profile::webapps::laravel
#
class profile::webapps::laravel (
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

  $_base = "/web/${application}/${environment}"

  selinux::fcontext {$_base:
    pathspec => "${_base}(/.*)?",
    seltype  => 'httpd_sys_content_t',
  }

  selinux::fcontext {"${_base}/bootstrap/cache":
    pathspec => "${_base}/bootstrap/cache(/.*)?",
    seltype  => 'httpd_sys_rw_content_t',
  }

  selinux::fcontext {"${_base}/storage":
    pathspec => "${_base}/storage(/.*)?",
    seltype  => 'httpd_sys_rw_content_t',
  }

  # RW dirs used by laravel
  file { ["${_base}/bootstrap", "${_base}/storage/app", "${_base}/storage/logs", "${_base}/storage/framework",
          "${_base}/storage/framework/cache", "${_base}/storage/framework/sessions", "${_base}/storage/framework/views"]:
    ensure => directory,
    owner  => $application,
    group  => 'apache',
    mode   => '0775',
  }

  file { [ "${_base}/bootstrap/cache", "${_base}/storage" ]:
    ensure  => directory,
    owner   => $application,
    group   => 'apache',
    mode    => '0775',
    seltype => 'httpd_sys_rw_content_t',
    require => [Selinux::Fcontext["${_base}/bootstrap/cache"], Selinux::Fcontext["${_base}/storage"]],
  }

  if !defined(Selboolean['httpd_can_network_connect_db']) {
    selboolean { 'httpd_can_network_connect_db':
      persistent => true,
      value      => on,
    }
  }

  logrotate::rule { 'laravel_logs':
    path         => "${_base}/storage/logs/*.log",
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

  # Configure composer github oauth if provided
  if $github_oauth {
    file { "/web/${application}/.composer":
      ensure => 'directory',
      owner  => $application,
      group  => $application,
      mode   => '0755',
    }

    file { "/web/${application}/.composer/auth.json":
      ensure  => 'file',
      owner   => $application,
      group   => $application,
      mode    => '0440',
      content => lark_sorted_json({
        'github-oauth' => {
          'github.com' => $github_oauth,
        },
      }),
    }
  }
}

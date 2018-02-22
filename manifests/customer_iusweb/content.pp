#
# Class: profile::customer_iusweb::content
# Purpose: Define for getting content onto a host.  We want certain
#   directories in place for the vhost, and we also allow for
#   various "running/webenv environments" - not to be confused
#   with Puppet or git environments.
#
define profile::customer_iusweb::content (
  $webenv_dirs = [],
) {

  validate_array($webenv_dirs)

  $content_base_dir = '/web' # This is important, and should come from outside.

  $sitename = $name
  $base_dirs_root = [ 'conf', 'logs', 'stats' ]
  $base_dirs_owner = [ 'pw', 'tmp' ]

  $base_dirs_root_full = regsubst($base_dirs_root, '^', "${content_base_dir}/${sitename}/")
  $base_dirs_owner_full = regsubst($base_dirs_owner, '^', "${content_base_dir}/${sitename}/")

  $webenv_dirs_full = regsubst($webenv_dirs, '^', "${content_base_dir}/${sitename}/")
  $pub_dirs_full = regsubst($webenv_dirs_full, '$', '/public_html')
  $index_files_full = regsubst($pub_dirs_full, '$', '/index.html')

  group { $sitename: ensure => present, }
  user { $sitename:
    ensure     => present,
    gid        => $sitename,
    home       => "${content_base_dir}/${sitename}",
    managehome => true,
  }

  file { $base_dirs_root_full:
    ensure  => directory,
    owner   => root,
    group   => root,
    mode    => '0755',
    require => User[$sitename],
  } ->
  file { $base_dirs_owner_full:
    ensure => directory,
    owner  => $sitename,
    group  => $sitename,
    mode   => '0755',
  } ->
  file { [ $webenv_dirs_full, $pub_dirs_full ]:
    ensure => directory,
    owner  => $sitename,
    group  => $sitename,
    mode   => '1755',
  } ->
  file { $index_files_full:
    ensure  => file,
    owner   => $sitename,
    group   => $sitename,
    mode    => '1755',
    content => inline_template("Work in Progress.  Site: ${sitename}, Env: See Ruby Parser. "),
  }

  # We need everything necessary from the updateAllWebConfigs script here.  This will be ugly until it is not.

  # - ssh keys?
  # - root owns sitedir?
  # - ssl certs come in somewhere via customer module for now
  # - SELinux needs more handling.  I've disabled it for Vagrant, but it needs to work
  #   for real environments.
}

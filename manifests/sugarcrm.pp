#
# Class name: profile::sugarcrm.pp
# Purpose: Setup SugarCRM
#
class profile::sugarcrm (
  $docroot = '/srv/www/crm/public',
  $owner = 'root',
  $group = 'root',
  $additional_packages = ['php53u-mbstring', 'php53u-mysql', 'php53u-pecl-apc',
    'php53u-imap', 'unzip'],
  $php_options = undef,
) {
  validate_string($docroot)
  validate_string($owner)
  validate_string($group)
  validate_array($additional_packages)
  validate_string($php_options)

  # Handle Parent Directories (crude)
  $docroot_parent = regsubst($docroot, '/[^/]+/?$', '')
  exec {"create_recursive_${docroot_parent}":
    command => "mkdir -m 0755 -p ${docroot_parent}",
    unless  => "test -d ${docroot_parent}",
    path    => ['/bin', '/usr/bin'],
  }

  ensure_resource('file', $docroot_parent, {
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Exec["create_recursive_${docroot_parent}"],
  })

  # Handle document root
  ensure_resource('file', $docroot, {
    ensure => directory,
    owner  => $owner,
    group  => $group,
    mode    => '0755',
  })

  # PHP Modules, or other packages for SugarCRM
  ensure_packages($additional_packages)

  $_phpconfig = $php_options ? {
    undef   => absent,
    default => file
  }
  # Now, assuming that we have php installed, we need some php settings in place.
  # We could go full bore and use one of the many PHP classes out there, then
  # select php.ini options to put into Hiera.  But for now, all we need is one file...
  file { '/etc/php.d/zz_SugarCRM.ini':
    ensure  => $_phpconfig,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => $php_options,
    require => Package[$additional_packages],
  }

  # Potentially in the future this could actually "setup" sugarCRM, but for now
  # we will just create the document root ;).

}

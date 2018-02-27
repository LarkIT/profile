#
# Class name: profile::magento.pp
# Purpose: Setup Magento
#
class profile::magento (
  $docroot = '/web/magento/public_html',
  $owner = 'magento',
  $group = 'magento',
  $additional_packages = ['unzip', 'php-mysql', 'php-gd', 'php-cli', 'php-mcrypt', 'ImageMagick'],
  $php_options = undef,
  $ssh_keys = {},
  $manage_ssh_keys = true,
  $purge_ssh_keys = true,

) {
  validate_absolute_path($docroot)
  validate_string($owner)
  validate_string($group)
  validate_array($additional_packages)
  validate_string($php_options)
  validate_hash($ssh_keys)
  validate_bool($manage_ssh_keys)
  validate_bool($purge_ssh_keys)

  # Handle Parent Directories (crude)
  $docroot_parent = regsubst($docroot, '/[^/]+/?$', '')
  exec {"create_recursive_${docroot_parent}":
    command => "mkdir -m 0755 -p ${docroot_parent}",
    unless  => "test -d ${docroot_parent}",
    path    => ['/bin', '/usr/bin'],
  }

  # Handle User/Group --- very bad stuff here
  ensure_resource('group', $group, {'ensure' => 'present'})
  ensure_resource('user', $owner, {
    'ensure'         => 'present',
    'gid'            => $group,
    'managehome'     => true,
    #'purge_ssh_keys' => $purge_ssh_keys,
    })

  ## SSH Keys for user
  if ($manage_ssh_keys) {
    # SSH Keys
    ensure_resource( 'profile::sshkeys', $owner, {
      keys            => $ssh_keys,
    })
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

  # PHP Modules, or other packages
  ensure_packages($additional_packages)

  $_ensure_php_custom = $php_options ? {
    undef   => 'absent',
    default => 'file'
  }
  # Now, assuming that we have php installed, we need some php settings in place.
  # We could go full bore and use one of the many PHP classes out there, then
  # select php.ini options to put into Hiera.  But for now, all we need is one file...
  file { '/etc/php.d/zz_Custom.ini':
    ensure  => $_ensure_php_custom,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => $php_options,
    require => Package[$additional_packages],
  }

  include '::n98magerun'

  class { '::n98magerun::install':
    installation_folder => $docroot,
  }

}

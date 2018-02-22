#
# Class name: profile::narrative.pp
# Purpose: Setup Narrative
#
class profile::narrative (
  $docroot = '/web/changethegameco.com/production/public_html',
  $owner = 'changethegameco',
  $group = 'changethegameco',
  $additional_packages = ['unzip'],
  $php_options = undef,
) {
  validate_string($docroot)
  validate_string($owner)
  validate_string($group)
  validate_array($additional_packages)
  if $php_options {
    validate_string($php_options)
  }

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
    'ensure'     => 'present',
    'gid'        => $group,
    'managehome' => true,
    })


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

  # PHP Modules, or other packages for Narrative
  ensure_packages($additional_packages)

  if $php_options {
    # Now, assuming that we have php installed, we need some php settings in place.
    # We could go full bore and use one of the many PHP classes out there, then
    # select php.ini options to put into Hiera.  But for now, all we need is one file...
    file { '/etc/php.d/zz_Narrative.ini':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => $php_options,
      require => Package[$additional_packages],
    }
  }
  # Potentially in the future this could actually "setup" narrative, but for now
  # we will just create the document root ;).

}

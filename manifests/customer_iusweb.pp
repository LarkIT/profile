#
# Class name: profile::customer_iusweb
# Purpose: Setup a webserver.  Content and Apache, with PHP from IUS.
#
# This class needs to be rewritten...  Prefereably using saz/ssh from the
# forge.
#
class profile::customer_iusweb (
  $create_vhosts       = {},
  $sites               = [],
  $webenv_dirs         = [],
  $additional_packages = [],
  $additional_classes  = [],
  $php_options         = undef,
) {

  validate_hash($create_vhosts)
  validate_array($sites)
  validate_array($webenv_dirs)
  validate_array($additional_packages)
  validate_array($additional_classes)
  if $php_options {
    validate_string($php_options)
  }

  ensure_packages($additional_packages)

  package { 'policycoreutils-python':
    ensure => present,
  }

  # Note that we're only dealing with SELinux as it pertains to Apache.
  # We shouldn't set scope for the box...
  $httpd_selinux_type = 'httpd_t'
  if hiera('selinux_enabled', false) {
    exec { 'enable_selinux':
      command => "/usr/sbin/semanage permissive -d ${httpd_selinux_type}",
      onlyif  => "/usr/sbin/semanage permissive -l | /bin/grep ^${httpd_selinux_type}",
      require => Package[policycoreutils-python],
      before  => Exec['download_content'],
    }
  } else {
    exec { 'disable_selinux':
      command => "/usr/sbin/semanage permissive -a ${httpd_selinux_type}",
      unless  => "/usr/sbin/semanage permissive -l | /bin/grep ^${httpd_selinux_type}",
      require => Package[policycoreutils-python],
      before  => Exec['download_content'],
    }
  }

  # We actually want to state some parameters here, so "contain" may not be
  # the way to do this.  We need firewall resources.
  contain apache

  # We want content...
  exec { 'download_content':
    command => '/usr/bin/git clone https://github.com/TJM/web-default /web/DEFAULT',
    unless  => '/usr/bin/stat /web/DEFAULT >& /dev/null',
    require => Class[Apache],
  }

#  if ($sites != [] and $webenv_dirs != []) {

    profile::customer_iusweb::content { $sites:
      webenv_dirs => $webenv_dirs,
      require     => Exec['download_content'],
    }

#  }

  $customer   = hiera('lk_customer')

  $ssl_certs  = "/etc/pki/tls/certs/${customer}-cert.pem"
  $ssl_keys   = "/etc/pki/tls/private/${customer}-key.pem"
  #$ssl_chains = "/etc/pki/tls/certs/${customer}-ca.pem"

  # We should check if the certs are defined in Hiera.  If they're not, then
  # use localhost-based certs.

    #file { $ssl_chains:
    #  ensure => file,
    #  mode   => '0644',
    #  source => "puppet:///modules/profile/customer_iusweb/${customer}-ca.pem"
    #} ->
    file { $ssl_certs:
      ensure  => file,
      mode    => '0644',
      #source => 'puppet:///modules/profile/customer_iusweb/localhost.crt',
      content => hiera('profile::customer_iusweb::sslcert'),
    } ->
    file { $ssl_keys:
      ensure  => file,
      mode    => '0600',
      #source  => 'puppet:///modules/profile/customer_iusweb/localhost.key',
      content => hiera('profile::customer_iusweb::sslkey'),
    }
  # End of installing cert

  class {'::apache::mod::php':
      package_name => 'php53u',
      # path       => "${::apache::params::lib_path}/libphp5.so",
  }

  create_resources('apache::vhost', $create_vhosts, {
    require => File[$ssl_keys],
  })

  # And a firewall...
  firewall { '100 INPUT allow http(s) from anyone':
    dport  => [ '80', '443' ],
    proto  => 'tcp',
    action => 'accept',
    chain  => 'INPUT',
  }

  firewall { '100 INPUT allow http(s) from anyone IPv6':
    dport    => [ '80', '443' ],
    proto    => 'tcp',
    action   => 'accept',
    chain    => 'INPUT',
    provider => 'ip6tables',
  }

  # Additional Classes for this module - this may change forms in the future
  include $additional_classes

  if $php_options {
    # Now, assuming that we have php installed, we need some php settings in place.
    # We could go full bore and use one of the many PHP classes out there, then
    # select php.ini options to put into Hiera.  But for now, all we need is one file...
    file { "/etc/php.d/zz_${customer}.ini":
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => inline_template('<%= @php_options %>'),
      require => Class[$additional_classes],
    }
  }
}

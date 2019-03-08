#
# === Class: profile::zabbix::server
#
# Setup Zabbix server
#
# === Parameters
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::zabbix::server': }
#
#
class profile::zabbix::server (
  $create_database             = undef,
  $database_type               = undef,
  $database_host               = undef,
  $database_port               = undef,
  $database_name               = undef,
  $database_user               = undef,
  $database_password           = undef,
  $apache_default_vhost        = undef,
  $apache_manage_vhost         = undef,
  $apache_ssl_cert             = undef,
  $apache_ssl_cert_path        = undef,
  $apache_ssl_chain            = undef,
  $apache_ssl_chain_path       = undef,
  $apache_ssl_key              = undef,
  $apache_ssl_key_path         = undef,
  $apache_use_ssl              = undef,
  $zabbix_web_server_name      = undef,
  $zabbix_web_timezone         = undef,
  $zabbix_web_url              = undef,
  $zabbix_server_cachesize     = undef,
  $zabbix_server_startpingers  = undef,
  $zabbix_server_starttrappers = undef,
  $zabbix_opsgenie_enabled     = undef,
  $zabbix_opsgenie_apikey      = undef,
  $zabbix_opsgenie_config_file = undef,
  $zabbix_opsgenie_command_url = undef,
  $zabbix_opsgenie_user        = undef,
  $zabbix_opsgenie_password    = undef,
){

  #Install mysql client for managing remote database
  include mysql::client

  #Configure apache
  class { 'apache':
    mpm_module    => 'prefork',
    default_vhost => false
  }

  include apache::mod::php

  file { $apache_ssl_key_path:
    ensure  => file,
    owner   => 'apache',
    group   => 'apache',
    mode    => '0600',
    content => $apache_ssl_key,
    before  => Class[ 'zabbix::web' ],
  }

  file { $apache_ssl_cert_path:
    ensure  => file,
    owner   => 'apache',
    group   => 'apache',
    mode    => '0600',
    content => $apache_ssl_cert,
    before  => Class[ 'zabbix::web' ],
  }

  file { $apache_ssl_chain_path:
    ensure  => file,
    owner   => 'apache',
    group   => 'apache',
    mode    => '0600',
    content => $apache_ssl_chain,
    before  => Class[ 'zabbix::web' ],
  }

  #Do not attempt to populate database with default structure unless $create_database is set to true
  #if $create_database == false {
  #  file { '/etc/zabbix/.schema.done':
  #    ensure => file,
	#  before => Class[ 'zabbix::database::mysql' ],
  #  }
  #}

  #Install zabbix-server
  class { 'zabbix::server':
    database_type        => $database_type,
    database_host        => $database_host,
    database_port        => $database_port,
    database_name        => $database_name,
    database_user        => $database_user,
    database_password    => $database_password,
    cachesize            => $zabbix_server_cachesize,
    startpingers         => $zabbix_server_startpingers,
    starttrappers        => $zabbix_server_starttrappers,
    manage_service       => true,
  }

  #Install zabbix-web frontend
  class { 'zabbix::web':
    zabbix_url         => $zabbix_web_url,
    zabbix_server      => $zabbix_web_zabbix_server,
    database_type      => $database_type,
    database_host      => $database_host,
    database_port      => $database_port,
    database_name      => $database_name,
    database_user      => $database_user,
    database_password  => $database_password,
    manage_vhost       => $apache_manage_vhost,
    default_vhost      => $apache_default_vhost,
    apache_use_ssl     => $apache_use_ssl,
    apache_ssl_key     => $apache_ssl_key_path,
    apache_ssl_cert    => $apache_ssl_cert_path,
    apache_ssl_chain   => $apache_ssl_chain_path,
    zabbix_timezone    => $zabbix_web_timezone,
    zabbix_server_name => $zabbix_web_server_name,
  }

  #Additional SELinux configuration

  include selinux
  selinux::module { 'zabbix-server-sock_file-unlink':
    ensure    => present,
    source_te => "puppet:///modules/${module_name}/zabbix/selinux/zabbix-server-sock_file-unlink.te",
    builder   => 'simple',
  }

  selinux::boolean { 'httpd_can_network_connect':
    ensure => 'on',
  }

  #OpsGenie integration
  if $zabbix_opsgenie_enabled {

    class { 'java':
      distribution => 'jre',
    }

    $opsgenie_zabbix_config = {
      opsgenie_apikey             => $zabbix_opsgenie_apikey,
      opsgenie_zabbix_command_url => $zabbix_opsgenie_command_url,
      opsgenie_zabbix_user        => $zabbix_opsgenie_user,
      opsgenie_zabbix_password    => $zabbix_opsgenie_password,
    }

    file { $zabbix_opsgenie_config_file:
      notify  => Service[ 'marid' ],
      ensure  => file,
      content => epp('profile/zabbix/opsgenie-integration.conf.epp', $opsgenie_zabbix_config ),
      require => Package[ 'opsgenie-zabbix' ],
    }

    service { 'marid':
      ensure  => running,
      enable  => true,
      require => Package[ 'opsgenie-zabbix' ],
    }

    package { 'opsgenie-zabbix':
    ensure  => present,
    }
  }
}

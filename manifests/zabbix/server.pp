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
  $mysql_install                  = undef,
  $mysql_root_password            = undef,
  $database_type                  = undef,
  $database_host                  = undef,
  $database_port                  = undef,
  $database_name                  = undef,
  $database_user                  = undef,
  $database_password              = undef,
  $apache_default_vhost           = undef,
  $apache_manage_vhost            = undef,
  $apache_ssl_cert                = undef,
  $apache_ssl_cert_path           = undef,
  $apache_ssl_chain               = undef,
  $apache_ssl_chain_path          = undef,
  $apache_ssl_key                 = undef,
  $apache_ssl_key_path            = undef,
  $apache_use_ssl                 = undef,
  $zabbix_web_server_name         = undef,
  $zabbix_web_timezone            = undef,
  $zabbix_web_url                 = undef,
  $zabbix_server_cachesize        = undef,
  $zabbix_server_startpingers     = undef,
  $zabbix_server_starttrappers    = undef,
  $zabbix_server_starthttppollers = undef,
  $zabbix_opsgenie_enabled        = undef,
  $zabbix_opsgenie_apikey         = undef,
  $zabbix_opsgenie_config_file    = undef,
  $zabbix_opsgenie_command_url    = undef,
  $zabbix_opsgenie_user           = undef,
  $zabbix_opsgenie_password       = undef,
  $zabbix_version                 = "4.2",
  $zabbix_package_state           = "latest",
  $aws_rds_monitoring             = false,
  $ssl_cert_monitoring            = false,
){

  #Install mysql
  include mysql::client

  if $mysql_install {
    class { 'mysql::server':
      root_password           => $mysql_root_password,
      remove_default_accounts => true,

    }

    mysql::db { $database_name:
      user     => $database_user,
      password => $database_password,
      host     => $database_host,
      grant    => ['ALL'],
      before   => Class[ 'zabbix::server' ],
    }

  }

  #Configure apache
  class { 'apache':
    mpm_module    => 'prefork',
    default_vhost => false
  }

  include apache::mod::php

  if $apache_use_ssl {

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
  }
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
    starthttppollers     => $zabbix_server_starthttppollers,
    manage_service       => true,
    zabbix_version       => $zabbix_version,
    zabbix_package_state => $zabbix_package_state,
  }

  #Install zabbix-web frontend
  class { 'zabbix::web':
    zabbix_url           => $zabbix_web_url,
    zabbix_server        => $zabbix_web_zabbix_server,
    database_type        => $database_type,
    database_host        => $database_host,
    database_port        => $database_port,
    database_name        => $database_name,
    database_user        => $database_user,
    database_password    => $database_password,
    manage_vhost         => $apache_manage_vhost,
    default_vhost        => $apache_default_vhost,
    apache_use_ssl       => $apache_use_ssl,
    apache_ssl_key       => $apache_ssl_key_path,
    apache_ssl_cert      => $apache_ssl_cert_path,
    apache_ssl_chain     => $apache_ssl_chain_path,
    zabbix_timezone      => $zabbix_web_timezone,
    zabbix_server_name   => $zabbix_web_server_name,
    zabbix_version       => $zabbix_version,
    zabbix_package_state => $zabbix_package_state,
  }

  selinux::boolean { 'httpd_can_network_connect':
    ensure => 'on',
  }

  #OpsGenie integration
  if $zabbix_opsgenie_enabled {

    $opsgenie_zabbix_config = {
      opsgenie_apikey             => $zabbix_opsgenie_apikey,
      opsgenie_zabbix_command_url => $zabbix_opsgenie_command_url,
      opsgenie_zabbix_user        => $zabbix_opsgenie_user,
      opsgenie_zabbix_password    => $zabbix_opsgenie_password,
    }
    
    # Install opsgenie-zabbix
    package { 'opsgenie-zabbix':
      provider => rpm,
      source   => "https://s3-us-west-2.amazonaws.com/opsgeniedownloads/repo/opsgenie-zabbix-2.22.0-1.all.noarch.rpm",
      ensure   => latest,
    }

    # Configure opsgenie-zabbix 
    file { $zabbix_opsgenie_config_file:
      ensure  => file,
      content => epp('profile/zabbix/opsgenie-integration.conf.epp', $opsgenie_zabbix_config ),
      require => Package[ 'opsgenie-zabbix' ],
    }

    # Install OEC
    package { 'oec':
      provider => rpm,
      source   => "https://opsgeniedownloads.s3-us-west-2.amazonaws.com/repo/oec-1.0.3-1.x86_64.rpm",
      ensure   => latest,
    }
    
    # Create OEC config file directory
    file { '/etc/opsgenie/oec':
    require => Package[ 'oec' ],
    ensure  => directory,
    owner   => 'opsgenie',
    group   => 'opsgenie',
    mode    => '0755',
    }
   
    # Copy OEC init script
    file { '/etc/systemd/system/oec.service':
    require => Package[ 'oec' ],
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => "puppet:///modules/${module_name}/zabbix/server_config/oec.service",
    notify  => Class['profile::systemd_reload']
    }

  }

  if $aws_rds_monitoring {
      
    file { '/usr/lib/zabbix/externalscripts/rds_stats.py':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0655',
    source  => "puppet:///modules/${module_name}/zabbix/server_proxy_scripts/rds_stats.py",
    }
  }

  if $ssl_cert_monitoring {

    file { '/usr/lib/zabbix/externalscripts/ssl_cert_check.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0655',
    source  => "puppet:///modules/${module_name}/zabbix/server_proxy_scripts/ssl_cert_check.sh",
    }
  }
}
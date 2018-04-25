#
# === Class: profile::zabbix::server
#
# Setup Zabbix server with the databae on RDS
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
  $create_database             = false,
  $zabbix_url                  = 'zabbix.lark-it.com',
  $database_type               = 'mysql',
  $database_host               = 'zabbix-db-prod.cnrkhevutr7w.us-west-2.rds.amazonaws.com',
  $database_port               = '3306',
  $database_name               = 'zabbix_prod',
  $database_user               = 'zabbix',
  $database_password           = 'password',
  $apache_use_ssl              = true,
  $apache_ssl_key_path         = '/etc/pki/tls/private/zabbix.key',
  $apache_ssl_cert_path        = '/etc/pki/tls/certs/zabbix.crt',
  $apache_ssl_chain_path       = '/etc/pki/tls/certs/zabbix.ca-bundle',
  $apache_ssl_key              = undef,
  $apache_ssl_cert             = undef,
  $apache_ssl_chain            = undef,
  $manage_vhost                = true,
  $default_vhost               = true,
  $agent_hostname              = 'lark-zabbix-01',
  $agent_listenip              = '0.0.0.0',
  $opsgenie_apikey             = undef,
  $opsgenie_zabbix_command_url = 'https://zabbix.lark-it.com/api_jsonrpc.php',
  $opsgenie_zabbix_user        = 'zabbix-opsgenie',
  $opsgenie_zabbix_password    = 'password',
  $opsgenie_zabbix_config_file = '/etc/opsgenie/conf/opsgenie-integration.conf',
  $zabbix_timezone             = 'America/Denver',
  $zabbix_server_name          = 'Lark IT Zabbix',
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
  if $create_database == false {
    file { '/etc/zabbix/.schema.done':
      ensure => file,
	  before => Class[ 'zabbix::database::mysql' ],
    }
  }

  #Install zabbix-server
  class { 'zabbix::server':
    database_type     => $database_type,
    database_host     => $database_host,
    database_port     => $database_port,
    database_name     => $database_name,
    database_user     => $database_user,
    database_password => $database_password,
  }

  #Install zabbix-web frontend
  class { 'zabbix::web':
    zabbix_url         => $zabbix_url,
    database_type      => $database_type,
    database_host      => $database_host,
    database_port      => $database_port,
    database_name      => $database_name,
    database_user      => $database_user,
    database_password  => $database_password,
    manage_vhost       => $manage_vhost,
    default_vhost      => $default_vhost,
    apache_use_ssl     => $apache_use_ssl,
    apache_ssl_key     => $apache_ssl_key_path,
    apache_ssl_cert    => $apache_ssl_cert_path,
    apache_ssl_chain   => $apache_ssl_chain_path,
    zabbix_timezone    => $zabbix_timezone,
    zabbix_server_name => $zabbix_server_name,
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
  class { 'java':
    distribution => 'jre',
  }

  $opsgenie_zabbix_config = {
    opsgenie_apikey             => $opsgenie_apikey,
    opsgenie_zabbix_command_url => $opsgenie_zabbix_command_url,
    opsgenie_zabbix_user        => $opsgenie_zabbix_user,
    opsgenie_zabbix_password    => $opsgenie_zabbix_password,
  }

  file { $opsgenie_zabbix_config_file:
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

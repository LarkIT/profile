#
# Class: profile::zabbix::proxy
# Purpose: Install and setup the Zabbix proxy for monitoring
#
# === Parameters
# [*zabbix_server*]
#  The Zabbix Server that the Zabbix agents should be configured to use
#
# Status: Work in Progress
#
class profile::zabbix::proxy (
    $presharedkey,
    $zabbix_proxy_name,
    $zabbix_server_host = 'zabbix.lark-it.com',
) {
  
  require profile::zabbix::agent

  group { 'zabbix':
    ensure => present,
  }

  file { '/etc/zabbix':
    ensure  => 'directory',
    owner   => 'root',
    group   => 'zabbix',
    mode    => '0640',
    require => Group['zabbix'],  
  }

  file { '/etc/zabbix/zabbix.psk':
    content => $presharedkey,
    owner   => 'root',
    group   => 'zabbix',
    mode    => '0660',
    require => File['/etc/zabbix'],
  }
  
  class { 'zabbix::proxy':
    zabbix_server_host => $zabbix_server_host,
    database_type      => 'sqlite',
    database_name      => '/tmp/database',
    tlspskfile         => '/etc/zabbix/zabbix.psk',
    tlspskidentity     => 'PSK',
    hostname           => $zabbix_proxy_name,
    require            => File['/etc/zabbix/zabbix.psk'],
    tlsconnect         => 'psk',
  }
}

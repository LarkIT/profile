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

  file { '/etc/zabbix/zabbix.psk':
    content => $presharedkey,
    owner   => 'root',
    group   => 'zabbix',
    mode    => '0660',  
  }
  
  class { 'zabbix::proxy':
    zabbix_server_host => $zabbix_server_host,
    database_type      => 'sqlite',
    database_name      => '/tmp/database',
    tlspskfile         => '/etc/zabbix/zabbix.psk',
    tlspskidentity     => 'PSK',
    hostname           => $zabbix_proxy_name,
    require            => File['/etc/zabbix/zabbix.psk'],
  }
}

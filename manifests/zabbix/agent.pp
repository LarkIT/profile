#
# Class: profile::zabbix::agent
# Purpose: Install and setup the Zabbix agent for monitoring
#
# === Parameters
# [*zabbix_server*]
#  The Zabbix Server that the Zabbix agents should be configured to use
#
# Status: Work in Progress
#
class profile::zabbix::agent (
  $zabbix_server = 'zabbix.lark-it.com'
){

  class { 'zabbix::agent':
    server         => $zabbix_server,
    serveractive   => $zabbix_server,
    manage_selinux => false,
  }

  firewall { '200 OUTPUT zabbix agent proxy port tcp':
    dport  => [ '10051' ],
    proto  => 'tcp',
    action => 'accept',
    chain  => 'OUTPUT',
  }
  firewall { '500 INPUT zabbix agent port tcp':
    dport  => [ '10050' ],
    proto  => 'tcp',
    action => 'accept',
    chain  => 'INPUT',
  }

  selinux::module { 'zabbix-agent':
    ensure => absent,
    before => Class['zabbix::agent'],
    notify => Service['zabbix-agent'],
  }

  selinux::permissive { 'zabbix_agent_t':
    ensure => present,
    notify => Service['zabbix-agent'],
  }

  unless (defined(Class['profile::zabbix::proxy'])) or (defined(Class['profile::zabbix::server'])) {
    selinux::boolean { 'zabbix_can_network':
      ensure => 'on',
    }
  }

  # Remove superseded script files
  file { '/opt/zabbix/':
    ensure => absent,
  }

  # Remove superseded Zabbix agent configuration
  file { '/etc/zabbix/zabbix_agentd.d/autodiscovery_linux.conf':
    notify  => Service['zabbix-agent'],
    ensure  => absent,
  }

  file { '/etc/zabbix/scripts/':
    ensure  => directory,
  }

  file { '/etc/zabbix/scripts/service_discovery.sh':
    require => File['/etc/zabbix/scripts/'],
    ensure  => file,
    source  => "puppet:///modules/${module_name}/zabbix/agent_scripts/service_discovery.sh",
    owner   => 'root',
    group   => 'root',
    mode    => '744',
  }

  file { '/etc/zabbix/zabbix_agentd.d/service_discovery.conf':
    require => Package['zabbix-agent'],
    notify  => Service['zabbix-agent'],
    ensure  => file,
    source  => "puppet:///modules/${module_name}/zabbix/agent_config/service_discovery.conf",
    owner   => 'root',
    group   => 'root',
    mode    => '644',
  }

  sudo::conf { 'zabbix':
    content => "zabbix  ALL=NOPASSWD: /etc/zabbix/scripts/service_discovery.sh",
  }
}

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
  $zabbix_server = 'zabbix.lark-it.com',
){

  class { 'zabbix::agent':
    server         => $zabbix_server,
    serveractive   => $zabbix_server,
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

  # SELinux configuration
  unless (defined(Class['profile::zabbix::proxy'])) or (defined(Class['profile::zabbix::server'])) {
    selinux::boolean { 'zabbix_can_network':
      ensure => 'on',
    }
  }

  selinux::boolean { 'zabbix_run_sudo':
    ensure => 'on',
  }

  #Clean up failed custom script attempt
  file { [ '/opt/zabbix',
           '/etc/sudoers.d/10_zabbix',
           '/etc/zabbix/zabbix_agentd.d/autodiscovery_linux.conf' ]:
    force   => true,
    ensure  => absent,
    notify  => Service['zabbix-agent'],
  }

  selinux::permissive { 'zabbix_agent_t':
    ensure => absent,
    notify => Service['zabbix-agent'],
  }

}

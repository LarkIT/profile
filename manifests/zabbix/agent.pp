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
  $zabbix_server        = 'zabbix.lark-it.com',
  $zabbix_version       = undef,
  $zabbix_package_state = undef,
){

  class { 'zabbix::agent':
    server               => $zabbix_server,
    serveractive         => $zabbix_server,
    zabbix_version       => $zabbix_version,
    zabbix_package_state => $zabbix_package_state,
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

  unless (defined(Class['profile::zabbix::proxy'])) or (defined(Class['profile::zabbix::server'])) {
    selinux::boolean { 'zabbix_can_network':
      ensure => 'on',
    }
  }

  selinux::boolean { 'zabbix_run_sudo':
    ensure => 'on',
  }

  selinux::permissive { 'zabbix_agent_t':
    ensure => present,
    notify => Service['zabbix-agent'],
  }

  file { '/usr/lib/zabbix/externalscripts/service_discovery.sh':
    ensure  => file,
    source  => "puppet:///modules/${module_name}/zabbix/agent_scripts/service_discovery.sh",
    owner   => 'zabbix',
    group   => 'zabbix',
    mode    => '755',
  }

  file { '/etc/zabbix/zabbix_agentd.d/service_discovery.conf':
    require => Package['zabbix-agent'],
    notify  => Service['zabbix-agent'],
    ensure  => file,
    source  => "puppet:///modules/${module_name}/zabbix/agent_config/service_discovery.conf",
    owner   => 'zabbix',
    group   => 'zabbix',
    mode    => '644',
  }

  sudo::conf { 'zabbix':
    content => [ "zabbix ALL=NOPASSWD: /usr/lib/zabbix/externalscripts/service_discovery.sh",
                 "zabbix ALL=NOPASSWD: /bin/ps" ],
  }

#Clean up superseded configuration

    file { [ '/opt/zabbix',
           '/etc/zabbix/zabbix_agentd.d/autodiscovery_linux.conf' ]:
    force   => true,
    ensure  => absent,
    notify  => Service['zabbix-agent'],
  }

  selinux::module { 'zabbix-agent-sudo':
    ensure    => absent,
    builder   => 'simple',
    source_te => "puppet:///modules/${module_name}/zabbix/selinux/zabbix-agent-sudo.te"
  }

}

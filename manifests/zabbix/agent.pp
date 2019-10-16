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
  $zabbix_version       = "4.2",
  $zabbix_package_state = "latest",
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

  # Zabbix agent SELinux permissive domain

  selinux::permissive { 'zabbix_agent_t':
    ensure => present,
    notify => Service['zabbix-agent'],
  }

  selinux::boolean { 'zabbix_run_sudo':
    ensure => 'on',
  }

  # Zabbix agent sudo configuration

  sudo::conf { 'zabbix-systemd':
    content  => [ "zabbix  ALL=NOPASSWD: /usr/local/bin/zbx_service_discovery.sh",
                  "zabbix  ALL=NOPASSWD: /usr/local/bin/zbx_service_restart_check.sh",
                  "zabbix  ALL=NOPASSWD: /bin/systemctl" ],
    priority => 15,
  }

  # Zabbix agent user parameter config files

  file { '/etc/zabbix/zabbix_agentd.d/userparameter_systemd_services.conf':
    ensure => file, 
    source => "puppet:///modules/${module_name}/zabbix/agent_config/userparameter_systemd_services.conf",
    mode   => '0644',
    notify => Service['zabbix-agent'],
  }
  
  # Zabbix agent custom scripts
  
  file { '/usr/local/bin/zbx_service_discovery.sh':
    ensure => file, 
    source => "puppet:///modules/${module_name}/zabbix/agent_scripts/zbx_service_discovery.sh",
    mode   => '0655',
    notify => Service['zabbix-agent'],
  }

  file { '/usr/loca/bin/zbx_service_restart_check.sh':
    ensure => file, 
    source => "puppet:///modules/${module_name}/zabbix/agent_scripts/zbx_service_restart_check.sh",
    mode   => '0655',
    notify => Service['zabbix-agent'],
  }


  # Clean up superseded configuration

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

  file { '/etc/zabbix/zabbix_agentd.d/service_discovery.conf':
    ensure  => absent,
    notify  => Service['zabbix-agent'],
  }

  file { '/usr/lib/zabbix/externalscripts/service_discovery.sh':
    ensure  => absent,
  }

  unless (defined(Class['profile::zabbix::proxy'])) or (defined(Class['profile::zabbix::server'])) {
    selinux::boolean { 'zabbix_can_network':
      ensure => 'off',
    }
  }
}

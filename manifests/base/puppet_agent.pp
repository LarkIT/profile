#
# === Class: profile::base::puppet_agent
#
# Configure Puppet Agent settings for service and config
#
class profile::base::puppet_agent {

  service { 'puppet':
    enable => true,
    ensure => 'running',
  }
}

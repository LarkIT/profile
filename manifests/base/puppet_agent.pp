#
# === Class: profile::base::puppet_agent
#
# Configure Puppet Agent settings for service and config
#
class profile::base::puppet_agent (
  $manage_service = true,
) {

if $manage_service {
    service { 'puppet':
      enable => true,
      ensure => 'running',
    }
  }
}

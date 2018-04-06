#
# === Class: profile::ssh
#
# Setup SSH Server
#
# === Parameters
#
# - port - SSH Port(s) Multiple should be specified as an array
#       Default: 22
#       NOTE: This only affects the firewall
# - admin_ips - IP addresses that can access admin interface (list)
#       Default: profile::firewall::admin_ips
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::ssh':
#     admin_ips         => ['10.0.250.1'],
#   }
#
# [*Hiera YAML*]
#   profile::ssh:port: 22222
#   profile::ssh::admin_ips: [10.0.250.1]
#
class profile::ssh (
  $port      = 22,
  $admin_ips = hiera_array('profile::firewall::admin_ips')
) {

  class { '::sshd':
    port     => $port,
    provider => 'sss',
  }

  $fw_admin_ips = suffix($admin_ips, '||admin-ssh')
  ensure_resource(profile::firewall::fwrule, any2array($fw_admin_ips), {
    direction => 'INPUT',
    port      => $port,
    proto     => 'tcp',
  })
}

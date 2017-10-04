#
# === Class: profile::gitlab
#
# Setup GitLab Server
#
# === Parameters
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::squid': }
#
#
class profile::gitlab (
  $puppet_ip = undef,
  $admin_ips = ['172.16.0.0/16'],
  $ports = [22, 443],
) {

  include ::gitlab

  # Firewall
  $puppet_ip_r = pick($puppet_ip, $server_facts['serverip'])
  firewall { "100 INPUT allow GitLab Access from PuppetServer ${puppet_ip_r}":
    dport  => $ports,
    proto  => 'tcp',
    action => 'accept',
    chain  => 'INPUT',
    source => $puppet_ip_r
  }

  any2array($admin_ips).each | String $ip | {
    firewall { "100 INPUT allow GitLab Access from ADMINS ${ip}":
      dport  => $ports,
      proto  => 'tcp',
      action => 'accept',
      chain  => 'INPUT',
      source => $ip,
    }
  }
}

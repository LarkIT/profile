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
  $admin_ips = ['172.20.0.0/16'],
  $ports = [22, 443],
) {
#gitlab::external_url: https://%{::fqdn}
#gitlab::nginx:
#  redirect_http_to_https: true,
#  ssl_certificate: /etc/puppetlabs/puppet/ssl/certs/%{trusted.certname}.pem
#  ssl_certificate_key: /etc/puppetlabs/puppet/ssl/private_keys/%{trusted.certname}.pem

#  include ::gitlab
  class{ 'gitlab':
    external_url => "https://${::fqdn}",
    nginx => { 
      'ssl_certificate'     => "/etc/puppetlabs/puppet/ssl/certs/${trusted.certname}.pem",
      'ssl_certificate_key' => "/etc/puppetlabs/puppet/ssl/private_keys/${trusted.certname}.pem",
    }   
  }

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

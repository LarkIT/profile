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
  
  class{ 'gitlab':
    external_url => "https://${::fqdn}",
    nginx => { 
      'ssl_certificate'     => "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem",
      'ssl_certificate_key' => "/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem",
    },
    gitlab_rails => {
      backup_keep_time               => '604800',
      backup_upload_remote_directory => 'gitlab-s3-backups',
      backup_upload_connection       => {
        'provider'        => 'AWS',
        'region'          => 'us-west-2',
        'use_iam_profile' => true 
      },
    },
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

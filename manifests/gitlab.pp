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
  $ports     = [22, 443],
  $s3_bucket = 'gitlab-s3-backups',
  $region    = $trusted['extensions']['pp_region'],
) {
  
  class{ 'gitlab':
    external_url => "https://${::fqdn}",
    nginx => { 
      'ssl_certificate'     => "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem",
      'ssl_certificate_key' => "/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem",
    },
    gitlab_rails => {
      backup_keep_time               => '604800',
      backup_upload_remote_directory => $s3_bucket,
      backup_upload_connection       => {
        'provider'        => 'AWS',
        'region'          => $region,
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

  cron { 'GITLab Backup secrets.json':
    command => "/usr/local/bin/aws s3 cp /etc/gitlab/gitlab-secrets.json s3://gitlab-s3-backups/",
    user    => 'root',
    hour    => [2, 10],
    minute  => 0,
  }

  cron { 'GITLab Backup':
    command => '/opt/gitlab/bin/gitlab-rake gitlab:backup:create CRON=1',
    user    => 'root',
    hour    => [2, 10],
    minute  => 1,
  }
}

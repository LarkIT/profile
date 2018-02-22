#
# === Class: profile::freepbx
#
# Setup Lark/CK FreePBX
#
# === Parameters
#
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::freepbx': }
#
#
class profile::freepbx (
  $use_ssl = true,
  $use_letsencrypt = true,
  $admin_ips = $profile::firewall::admin_ips,
){
  service { 'asterisk':
    ensure => 'running',
    enable => true,
  }

  firewall { '500 FreePBX inbound TCP connections':
    action => 'accept',
    state  => 'NEW',
    chain  => 'INPUT',
    proto  => 'tcp',
    dport  => [ 80, 443],
  }

  # FIXME: This is bad, we should put *some* effort into limiting this
  firewall { '500 FreePBX inbound UDP connections':
    action => 'accept',
    state  => 'NEW',
    chain  => 'INPUT',
    proto  => 'udp',
    dport  => [ '1024:65535' ],
  }
  firewall { '500 FreePBX outbound UDP connections':
    action => 'accept',
    state  => 'NEW',
    chain  => 'OUTPUT',
    proto  => 'udp',
    dport  => [ '1024:65535' ],
  }
}

#
# === Class: profile::squid
#
# Setup Squid Proxy Server
#
# === Parameters
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::squid': }
#
#
class profile::squid (
  $source_ip = undef,
) {

  # LVM: DataDisk Mounts - please see hieradata/role/pulp.yaml
  include ::squid3


  # Firewall
  firewall { "100 INPUT allow squid proxy from ${source_ip}":
    dport  => [ 3128 ],
    proto  => 'tcp',
    action => 'accept',
    chain  => 'INPUT',
    source => $source_ip
  }

  firewall { '200 OUTPUT allow http(s) to all':
    dport  => [ '80', '443' ],
    proto  => 'tcp',
    action => 'accept',
    chain  => 'INPUT',
  }

  firewall { '200 OUTPUT allow http(s) to all IPv6':
    dport    => [ '80', '443' ],
    proto    => 'tcp',
    action   => 'accept',
    chain    => 'INPUT',
    provider => 'ip6tables',
  }

  if str2bool($::settings::storeconfigs) {
    # Let other systems connect outbound to us.
    @@firewall { "200 OUTPUT HTTP Proxy (squid) at ${::ipaddress}:3128":
      dport       => [3128],
      proto       => 'tcp',
      action      => 'accept',
      chain       => 'OUTPUT',
      destination => $::ipaddress,
      tag         => 'fw_proxy_out',
    }
  }
}

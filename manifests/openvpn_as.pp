#
# === Class: profile::openvpn_as
#
# Setup openvpn access server
#
# === Parameters
#
#
class profile::openvpn_as (
  $port                           = 1194,
  $package_version                = $openvpn_as::package_version,
  $admin_ips                      = $profile::firewall::admin_ips,
  $manage_selinux                 = hiera('selinux_enabled', false),
) {

  include ::openvpn_as

  include ::repos::openvpn_as
  # Firewall stuff
  if str2bool($::settings::storeconfigs) {
    # Let other systems connect outbound to us.
    @@firewall { "200 OUTPUT allow openvpn server udp at ${::ipaddress}:${port}":
      dport       => $port,
      proto       => 'udp',
      action      => 'accept',
      chain       => 'OUTPUT',
      destination => $::ipaddress,
      tag         => "ptag_${::environment}_out_admins_to_openvpn",
    }
    # Allow inbound connections.
    Firewall <<| tag == "ptag_${::environment}_in_admins_to_openvpn" |>>

    # Admin Firewall Rules (currently only accepting hard coded rules)
    $fw_admin_ips = suffix($admin_ips, '||admin-openvpn')
    ensure_resource(profile::firewall::fwrule, any2array($fw_admin_ips), {
      direction => 'INPUT',
      port      => $port,
      proto     => 'udp',
    })
  }

  # SELinux Stuff
  # semanage port -a -t $type -p $port
  # We may need to add some "conditionals" around this in the future
  if hiera('selinux_enabled', false) {
    selinux::port { 'allow-openvpn-port-selinux':
      context  => 'openvpn_port_t',
      protocol => 'udp',
      port     => $port,
    }
  }

  #  if $server {
    firewall { '550 allow OpenVPN UDP inbound':
      action => 'accept',
      state  => 'NEW',
      proto  => 'udp',
      dport  => [1194],
    }

    firewall { '550 allow OpenVPN TCP inbound':
      action => 'accept',
      state  => 'NEW',
      proto  => 'tcp',
      dport  => [80, 443],
    }

    firewall { '560 allow OpenVPN TCP inbound admin':
      action => 'accept',
      state  => 'NEW',
      proto  => 'tcp',
      dport  => [943],
    }

    firewall { '551 NAT VPN traffic':
      table    => 'nat',
      chain    => 'POSTROUTING',
      jump     => 'MASQUERADE',
      proto    => 'all',
      outiface => 'eth0',
      source   => $vpn_network,
    }

    firewall { '551 FORWARD VPN traffic':
      chain       => 'FORWARD',
      action      => 'accept',
      iniface     => 'tun0',
      proto       => 'all',
      source      => $vpn_network,
      destination => '0.0.0.0/0',
    }

    firewall { '551 FORWARD return VPN traffic':
      chain  => 'FORWARD',
      action => 'accept',
      proto  => 'all',
      state  => ['RELATED','ESTABLISHED'],
    }

    firewall { '550 allow OpenVPN TCP inbound IPv6':
      action   => 'accept',
      state    => 'NEW',
      proto    => 'udp',
      dport    => [1194],
      provider => 'ip6tables',
    }

    firewall { '550 allow OpenVPN UDP inbound IPv6':
      action   => 'accept',
      state    => 'NEW',
      proto    => 'tcp',
      dport    => [443],
      provider => 'ip6tables',
    }


}

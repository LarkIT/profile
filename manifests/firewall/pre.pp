#
# === Class: profile::firewall::pre
#
class profile::firewall::pre {

  Firewall {
    require => undef,
    action  => 'accept',
  }

  firewall { '000 INPUT accept all to lo interface':
    chain   => 'INPUT',
    proto   => 'all',
    iniface => 'lo',
  }

  firewall { '000 OUTPUT accept all from lo interface':
    chain    => 'OUTPUT',
    proto    => 'all',
    outiface => 'lo',
  }

  firewall { '001 INPUT allow icmp type 8 (ping IPv4)':
    chain    => 'INPUT',
    proto    => 'icmp',
    icmp     => 'echo-request',
    limit    => '10/sec',
    provider => 'iptables',
  }

  firewall { '001 INPUT allow icmp type 0 (ping IPv4)':
    chain    => 'INPUT',
    proto    => 'icmp',
    icmp     => 'echo-reply',
    limit    => '10/sec',
    provider => 'iptables',
  }

  firewall { '001 OUTPUT allow icmp type 8 (ping IPv4)':
    chain    => 'OUTPUT',
    proto    => 'icmp',
    icmp     => 'echo-request',
    provider => 'iptables',
  }

  #  firewall { '002 INPUT reject local traffic not on loopback interface':
  #  chain       => 'INPUT',
  #  destination => '127.0.0.1/8',
  #  proto       => 'all',
  #  iniface     => '! lo',
  #  action      => 'reject',
  #}

  firewall { '003 INPUT allow related and established rules':
    chain   => 'INPUT',
    proto   => 'all',
    ctstate => ['RELATED', 'ESTABLISHED'],
  }

  firewall { '004 OUTPUT allow related and established rules':
    chain   => 'OUTPUT',
    proto   => 'all',
    ctstate => ['RELATED', 'ESTABLISHED'],
  }

  # Allow DHCP packets in...
  firewall { '049 INPUT allow dhcp udp from anyone internal':
    dport  => [ '67', '68' ],
    proto  => 'udp',
    action => 'accept',
    chain  => 'INPUT',
  }

  # Allow DHCP packets out...
  firewall { '050 OUTPUT allow dhcp udp from anyone internal':
    dport  => [ '67', '68' ],
    proto  => 'udp',
    action => 'accept',
    chain  => 'OUTPUT',
  }

  firewall { '098 OUTPUT allow 8140/tcp outbound to puppetmaster':
    destination => $::server_ip,
    chain       => 'OUTPUT',
    proto       => 'tcp',
    dport       => '8140',
  }

}

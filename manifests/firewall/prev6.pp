#
# === Class: profile::firewall::prev6
#

#Essentially same thing as pre, except with IPv6 provider specified
class profile::firewall::prev6 {

  Firewall {
    require => undef,
    action  => 'accept',
  }

  ##INBOUND

  firewall { '000 INPUT accept all to lo interface IPv6':
    chain    => 'INPUT',
    proto    => 'all',
    iniface  => 'lo',
    provider => 'ip6tables',
  }

  firewall { '001 INPUT allow icmp type 1 (destination unreachable)':
    chain    => 'INPUT',
    proto    => 'ipv6-icmp',
    icmp     => '1',
    limit    => '10/sec',
    provider => 'ip6tables',
  }

  firewall { '002 INPUT allow icmp type 2 (too big)':
    chain    => 'INPUT',
    proto    => 'ipv6-icmp',
    icmp     => '2',
    limit    => '10/sec',
    provider => 'ip6tables',
  }

  firewall { '002 INPUT allow icmp type 3 (time-exceeded)':
    chain    => 'INPUT',
    proto    => 'ipv6-icmp',
    icmp     => '3',
    provider => 'ip6tables',
  }

  firewall { '002 INPUT allow icmp type 4 (parameter-problem)':
    chain    => 'INPUT',
    proto    => 'ipv6-icmp',
    icmp     => '4',
    provider => 'ip6tables',
  }


  firewall { '001 INPUT allow icmp type 128 (ping IPv6)':
    chain    => 'INPUT',
    proto    => 'ipv6-icmp',
    icmp     => 'echo-request',
    limit    => '10/sec',
    provider => 'ip6tables',
  }

  firewall { '001 INPUT allow icmp type 129 (ping IPv6)':
    chain    => 'INPUT',
    proto    => 'ipv6-icmp',
    icmp     => 'echo-reply',
    limit    => '10/sec',
    provider => 'ip6tables',
  }

  firewall { '002 INPUT allow icmp type 135 (neighbor solicitation)':
    chain    => 'INPUT',
    proto    => 'ipv6-icmp',
    icmp     => '135',
    provider => 'ip6tables',
  }

  firewall { '001 INPUT allow icmp type 136 (neighbor advertisement)':
    chain    => 'INPUT',
    proto    => 'ipv6-icmp',
    icmp     => '136',
    limit    => '10/sec',
    provider => 'ip6tables',
  }

  firewall { '002 INPUT allow icmp type 137 (redirect)':
    chain    => 'INPUT',
    proto    => 'ipv6-icmp',
    icmp     => '137',
    provider => 'ip6tables',
  }

  firewall { '010 INPUT allow related and established rules IPv6':
    chain    => 'INPUT',
    proto    => 'all',
    ctstate  => ['RELATED', 'ESTABLISHED'],
    provider => 'ip6tables',
  }

  ##OUTBOUND

  firewall { '000 OUTPUT accept all from lo interface IPv6':
    chain    => 'OUTPUT',
    proto    => 'all',
    outiface => 'lo',
    provider => 'ip6tables',
  }

  firewall { '002 OUTPUT allow icmp type 1 (destination unreachable)':
    chain    => 'OUTPUT',
    proto    => 'ipv6-icmp',
    icmp     => '1',
    limit    => '10/sec',
    provider => 'ip6tables',
  }

  firewall { '002 OUTPUT allow icmp type 2 (too big)':
    chain    => 'OUTPUT',
    proto    => 'ipv6-icmp',
    icmp     => '2',
    limit    => '10/sec',
    provider => 'ip6tables',
  }

  firewall { '002 OUTPUT allow icmp type 3 (time-exceeded)':
    chain    => 'OUTPUT',
    proto    => 'ipv6-icmp',
    icmp     => '3',
    provider => 'ip6tables',
  }

  firewall { '002 OUTPUT allow icmp type 4 (parameter-problem)':
    chain    => 'OUTPUT',
    proto    => 'ipv6-icmp',
    icmp     => '4',
    provider => 'ip6tables',
  }

  firewall { '001 OUTPUT allow icmp type 128 (ping IPv6)':
    chain    => 'OUTPUT',
    proto    => 'ipv6-icmp',
    icmp     => 'echo-request',
    provider => 'ip6tables',
  }

  firewall { '001 OUTPUT allow icmp type 129 (ping IPv6)':
    chain    => 'OUTPUT',
    proto    => 'ipv6-icmp',
    icmp     => 'echo-reply',
    provider => 'ip6tables',
  }

  firewall { '002 OUTPUT allow icmp type 133 (router solicitation)':
    chain     => 'OUTPUT',
    proto     => 'ipv6-icmp',
    icmp      => '133',
    provider  => 'ip6tables',
    hop_limit =>  '255',
  }

  firewall { '002 OUTPUT allow icmp type 135 (neighbor solicitation)':
    chain     => 'OUTPUT',
    proto     => 'ipv6-icmp',
    icmp      => '135',
    provider  => 'ip6tables',
    hop_limit =>  '255',
  }

  firewall { '002 OUTPUT allow icmp type 136 (neighbor advertisement)':
    chain     => 'OUTPUT',
    proto     => 'ipv6-icmp',
    icmp      => '136',
    provider  => 'ip6tables',
    hop_limit =>  '255',
  }

  firewall { '010 OUTPUT allow related and established rules IPv6':
    chain    => 'OUTPUT',
    proto    => 'all',
    ctstate  => ['RELATED', 'ESTABLISHED'],
    provider => 'ip6tables',
  }

  firewall { '098 OUTPUT allow 8140/tcp outbound to puppetmaster IPv6':
    chain    => 'OUTPUT',
    proto    => 'tcp',
    dport    => '8140',
    provider => 'ip6tables',
  }

}

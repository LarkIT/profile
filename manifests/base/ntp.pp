# Class: profile::base::ntp
#
# Purpose: Setup NTP on the host, and ensure that it's monitored.
#
#
class profile::base::ntp {

  # Include the service
  include '::ntp'

  service { 'ntpdate':
    enable => true
  }

  service { 'chronyd':
    enable => false
  }

  # Note that at some point, these may become exported resources that point to the IPA server.
  firewall { '100 OUTPUT allow ntp tcp':
    chain  => 'OUTPUT',
    action => 'accept',
    dport  => '123',
    proto  => 'tcp',
  }

  firewall { '100 OUTPUT allow ntp udp':
    chain  => 'OUTPUT',
    action => 'accept',
    dport  => '123',
    proto  => 'udp',
  }

  firewall { '100 OUTPUT allow ntp tcp IPv6':
    chain    => 'OUTPUT',
    action   => 'accept',
    dport    => '123',
    proto    => 'tcp',
    provider => 'ip6tables',
  }

  firewall { '100 OUTPUT allow ntp udp IPv6':
    chain    => 'OUTPUT',
    action   => 'accept',
    dport    => '123',
    proto    => 'udp',
    provider => 'ip6tables',
  }
}

#
# === Class: profile::ntp
#
# Setup ntp client
#
# === Parameters
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::squid': }
#
#

class profile::ntp {

  # Include the service
  #include '::ntp'

  if $ec2_userdata {
    $ntp_servers = [ '169.254.169.123' ]
  } else {
    $ntp_servers = lookup('ntp::servers', Array[String], 'unique')
  }

  class{ '::ntp':
    servers => $ntp_servers,
  }

  service { 'ntpdate':
    enable  => true,
    require => Class[ 'ntp' ],
  }

  service { 'chronyd':
    enable  => false,
    require => Class[ 'ntp' ],
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

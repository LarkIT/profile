#
# === Class: profile::firewall::postv6
#
#Essentially same thing as post, except with IPv6 Provider specified
class profile::firewall::postv6 {

  Firewall {
    before => undef,
  }

  firewall { '900 log dropped input chain IPv6':
    chain      => 'INPUT',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => 'FIREWALL-Input-Rejected: ',
    proto      => 'all',
    burst      => '5',
    limit      => '30/min',
    provider   => 'ip6tables',
  }

  firewall { '900 log dropped forward chain IPv6':
    chain      => 'FORWARD',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => 'FIREWALL-Forward-Rejected: ',
    proto      => 'all',
    burst      => '5',
    limit      => '30/min',
    provider   => 'ip6tables',
  }

  firewall { '900 log dropped output chain IPv6':
    chain      => 'OUTPUT',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => 'FIREWALL-Output-Rejected: ',
    proto      => 'all',
    burst      => '5',
    limit      => '30/min',
    provider   => 'ip6tables',
  }

  firewall { '910 drop all other input requests IPv6':
    chain    => 'INPUT',
    action   => 'drop',
    proto    => 'all',
    provider => 'ip6tables',
  }

  firewall { '910 drop all other forward requests IPv6':
    chain    => 'FORWARD',
    action   => 'drop',
    proto    => 'all',
    provider => 'ip6tables',
  }

  firewall { '910 drop all other output requests IPv6':
    chain    => 'OUTPUT',
    action   => 'drop',
    proto    => 'all',
    provider => 'ip6tables',
  }

}

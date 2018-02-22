#
# === Class: profile::firewall::post
#
class profile::firewall::post {

  Firewall {
    before => undef,
  }

  firewall { '900 log dropped input chain':
    chain      => 'INPUT',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => 'FIREWALL-Input-Rejected: ',
    proto      => 'all',
    burst      => '5',
    limit      => '30/min',
  }

  firewall { '900 log dropped forward chain':
    chain      => 'FORWARD',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => 'FIREWALL-Forward-Rejected: ',
    proto      => 'all',
    burst      => '5',
    limit      => '30/min',
  }

  firewall { '900 log dropped output chain':
    chain      => 'OUTPUT',
    jump       => 'LOG',
    log_level  => '6',
    log_prefix => 'FIREWALL-Output-Rejected: ',
    proto      => 'all',
    burst      => '5',
    limit      => '30/min',
  }

  firewall { '910 drop all other input requests':
    chain  => 'INPUT',
    action => 'drop',
    proto  => 'all',
  }

  firewall { '910 drop all other forward requests':
    chain  => 'FORWARD',
    action => 'drop',
    proto  => 'all',
  }

  firewall { '910 drop all other output requests':
    chain  => 'OUTPUT',
    action => 'drop',
    proto  => 'all',
  }

}

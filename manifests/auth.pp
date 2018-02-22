#
# Class: profile::auth
# Purpose: Setup authentication
#   Note: The firewall stuff in here will need a refactor.  This is both
#     known and anticipated.
#
class profile::auth (
  $authtype = undef,
  $auth_ips = [],
) {

  if $authtype {
    $authtype_supported = [ '^ipa$', '^ad$' ]
    validate_re($authtype, $authtype_supported)

    firewall { '200 OUTPUT allow IPA ports tcp':
      chain       => 'OUTPUT',
      action      => 'accept',
      dport       => [ '88', '389', '464', '636'],
      proto       => 'tcp',
      destination => $auth_ips,
    }

    firewall { '200 OUTPUT allow IPA ports udp':
      chain       => 'OUTPUT',
      action      => 'accept',
      dport       => [ '88', '464'],
      proto       => 'udp',
      destination => $auth_ips,
    }
  } else {
    User <| tag == 'EMPTY' |>
    Group <| tag == 'EMPTY' |>
  }

  firewall { '200 OUTPUT allow DNS lookups tcp':
    chain  => 'OUTPUT',
    action => 'accept',
    state  => ['NEW'],
    dport  => '53',
    proto  => 'tcp',
  }

  firewall { '200 OUTPUT allow DNS lookups udp':
    chain  => 'OUTPUT',
    action => 'accept',
    state  => ['NEW'],
    dport  => '53',
    proto  => 'udp',
  }

  firewall { '200 OUTPUT allow DNS lookups tcp IPv6':
    chain    => 'OUTPUT',
    action   => 'accept',
    state    => ['NEW'],
    dport    => '53',
    proto    => 'tcp',
    provider => 'ip6tables',
  }

  firewall { '200 OUTPUT allow DNS lookups udp IPv6':
    chain    => 'OUTPUT',
    action   => 'accept',
    state    => ['NEW'],
    dport    => '53',
    proto    => 'udp',
    provider => 'ip6tables',
  }

}

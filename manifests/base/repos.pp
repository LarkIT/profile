#
# Class: profile::base::repos
# Purpose: Setup local yum repositories
#
class profile::base::repos (
  $extrarepos = [],
  $yum_server = '52.38.50.214/32',
) {

  validate_array($extrarepos)

  include ::yum
  include ::repos::centos
  include ::repos::epel
  include ::repos::puppet
  include ::repos::larkit

  # Additional repos...
  include $extrarepos

  Yumrepo <| |> -> Package <| provider != 'rpm' |>

  firewall { '200 OUTPUT yum ports tcp':
    dport       => [ '80', '443' ],
    proto       => 'tcp',
    action      => 'accept',
    chain       => 'OUTPUT',
    destination => $yum_server,
  }

  # Firewall the ports... not exactly very elegant... ;)
  firewall { '899 OUTPUT log yum ports tcp':
    dport      => [ '80', '443' ],
    proto      => 'tcp',
    chain      => 'OUTPUT',
    jump       => 'LOG',
    tcp_flags  => 'FIN,SYN,RST,ACK SYN',
    log_prefix => 'FIREWALL-yum-cleanup: ',
  }

  firewall { '899 OUTPUT log yum ports tcp IPv6':
    dport      => [ '80', '443' ],
    proto      => 'tcp',
    chain      => 'OUTPUT',
    jump       => 'LOG',
    tcp_flags  => 'FIN,SYN,RST,ACK SYN',
    log_prefix => 'FIREWALL-yum-cleanup: ',
    provider   => 'ip6tables',
  }

  firewall { '900 OUTPUT yum ports tcp':
    dport  => [ '80', '443' ],
    proto  => 'tcp',
    action => 'accept',
    chain  => 'OUTPUT',
  }

  firewall { '900 OUTPUT yum ports tcp IPv6':
    dport    => [ '80', '443' ],
    proto    => 'tcp',
    action   => 'accept',
    chain    => 'OUTPUT',
    provider => 'ip6tables',
  }

}

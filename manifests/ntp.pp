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
  class{ '::ntp':
    servers => [ '169.254.169.123' ],
  }

  service { 'ntpdate':
    enable  => true,
    require => Class[ 'ntp' ],
  }

  service { 'chronyd':
    enable  => false,
    require => Class[ 'ntp' ],
  }
}

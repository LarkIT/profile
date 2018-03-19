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
}

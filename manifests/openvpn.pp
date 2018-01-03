#
# === Class: profile::openvpn
#
# Setup OpenVPN Access Server
#
# === Parameters
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::squid': }
#
#
class profile::openvpn (
  $service = 'openvpnas',
  $domain  = $fqdn,
) {

  # Repo
  include ::repos::openvpn

  class{ 'profile::letsencrypt':
    service => $service, 
    domains => [ $domain ],
  }

  # OpenVPN_AS - please see https://github.com/LarkIT/puppet-openvpn_as
  class{ 'openvpn_as':
    require => Class[ 'profile::letsencrypt' ],
  }

  file{ '/usr/local/openvpn_as/etc/web-ssl/server.key':
    ensure => link,
    mode   => '0600',
    target => "/etc/letsencrypt/live/${domain}/privkey.pem",
    notify => Service[ 'openvpnas' ],
  }

  file{ '/usr/local/openvpn_as/etc/web-ssl/server.crt':
    ensure => link,
    mode   => '0600',
    target => "/etc/letsencrypt/live/${domain}/cert.pem",
    notify => Service[ 'openvpnas' ],
  }
}

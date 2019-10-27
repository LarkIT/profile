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
  $service            = 'openvpnas',
  $domain             = $fqdn,
  $enable_lestencrypt = false,
) {

  # Repo
  include ::repos::openvpn_as

  if $enable_lestencrypt == true {
    class{ 'profile::letsencrypt':
      service => $service,
      domains => [ $domain ],
      before  => Class[ 'openvpn_as' ],
    }

    file{ '/usr/local/openvpn_as/etc/web-ssl/server.key':
      ensure  => link,
      mode    => '0600',
      target  => "/etc/letsencrypt/live/${domain}/privkey.pem",
      require => Class[ 'profile::letsencrypt' ],
      notify  => Service[ 'openvpnas' ],
    }

    file{ '/usr/local/openvpn_as/etc/web-ssl/server.crt':
      ensure  => link,
      mode    => '0600',
      target  => "/etc/letsencrypt/live/${domain}/cert.pem",
      require => Class[ 'profile::letsencrypt' ],
      notify  => Service[ 'openvpnas' ],
    }
    firewall { '700 INPUT Certbot port TCP 80':
      dport  => '80',
      proto  => 'tcp',
      action => 'accept',
      chain  => 'INPUT',
    }
  }

  # OpenVPN_AS - please see https://github.com/LarkIT/puppet-openvpn_as
  include openvpn_as

}

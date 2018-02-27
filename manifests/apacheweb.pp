#
# Class name: profile::apacheweb
# Purpose: Setup an Apache web server.
#
# === Parameters
#
# [*vhosts*]
#   Virtual Hosts to create (passed to puppetlabs-apache::vhost)
#   (Hash) Defaults to {}
#
# [*ports*]
#   List of ports to open in the firewall
#   (Array) Defaults to [80,443]
#
# [*additional_mods*]
#   List of apache modules to add (passed to puppetlabs-apache::mod)
#   (Array) Defaults to []
#
#
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::apacheweb':
#     $vhosts    => {#FILLMEINLATER#},
#     $ports     => [80, 443],
#   }
#
# [*Hiera YAML*]
#   profile::apacheweb::vhosts:
#     - vhost.domain.com:
#       - vhost param: value
#
#
class profile::apacheweb (
  $vhosts = {},
  $ports = [80, 443],
  $additional_mods = [],
) {
  validate_hash($vhosts)
  validate_array($additional_mods)

  include ::apache
  create_resources('::apache::vhost', $vhosts)
  apache::mod { $additional_mods: }

  # And a firewall...
  firewall { '100 INPUT allow http(s) from anywhere':
    dport  => $ports,
    proto  => 'tcp',
    action => 'accept',
    chain  => 'INPUT',
  }

  firewall { '100 INPUT allow http(s) from anywhere IPv6':
    dport  => $ports,
    proto  => 'tcp',
    action => 'accept',
    chain  => 'INPUT',
  }


}

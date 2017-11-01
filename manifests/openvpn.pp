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
) {

  # Repo
  include ::repos::openvpn

  # OpenVPN_AS - please see https://github.com/LarkIT/puppet-openvpn_as
  #include ::openvpn_as
  include ::openvpn

  # Firewall should be handled by OpenVPN-AS Software?

}

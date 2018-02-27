#
# === Class: profile::sftp::client
#
# Setup simple Solr Server
#
# === Parameters
#
# - server_ips - IP addresses that can (statically) access solr port (list) - default []
# - port - Port(s) - Default: 22 (profile::sftp::port)
#
class profile::sftp::client (
  $server_ips = [],
  $port = $profile::sftp::port,
) inherits profile::sftp {

  validate_array($server_ips)
  #validate_int($port)

  # Firewall
  if str2bool($::settings::storeconfigs) {
    # Let other systems connect outbound to us.
    @@firewall { "200 INPUT allow sftp access from ${::ipaddress} to ${port}":
      dport  => $port,
      proto  => 'tcp',
      action => 'accept',
      chain  => 'INPUT',
      source => $::ipaddress,
      tag    => "fw_${::environment}_${::client}_${::app_tier}_${::app_name}_sftp_in_from_sftp_clients",
    }
    # Allow inbound connections.
    Firewall <<| tag == "fw_${::environment}_${::client}_${::app_tier}_${::app_name}_sftp_out_to_sftp_server" |>>

    # Pick up the hosts file entry that was left for us.
    Host <<| tag == "host_${::environment}_${::client}_${::app_tier}_${::app_name}_sftp_server" |>>
  }

  # Manual firewall rule overrides
  $fw_server_ips = suffix($server_ips, '||SFTP-Server-Access')
  ensure_resource(profile::firewall::fwrule, $fw_server_ips, {
    direction => 'OUTPUT',
    port      => $port,
    proto     => 'tcp',
  })

}

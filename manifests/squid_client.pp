# profile::squid_client - HTTP Proxy Squid Clients
class profile::squid_client (
  $server_name = undef,
  $server_ip = undef, # override
  $port = 3128,
  $no_proxy = ".${::networking['domain']}",
) {

  if ($server_name) {
    ## Proxy Environment
    file { '/etc/environment':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      content => template('profile/squid_client/environment.erb'),
    }

    ## Firewall
    if str2bool($::settings::storeconfigs) {
        # Pick up the rules that were left for us.
        Firewall <<| tag == 'fw_proxy_out' |>>
    }

    #Is this redundant with the exported resource in squid.pp?
    if ($server_ip) {
      firewall { "200 OUTPUT HTTP Proxy to Squid Server ${server_ip} 3128/tcp":
        dport       => [3128],
        proto       => 'tcp',
        action      => 'accept',
        chain       => 'OUTPUT',
        destination => $server_ip,
      }
    }
  }
}

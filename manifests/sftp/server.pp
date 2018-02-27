#
# === Class: profile::sftp
#
# Setup sftp (proftpd)
#
# === Parameters
#
# - port - sftp Port Multiple should be specified as an array
#       Default: 22 (profile::sftp::port)
# - client_ips - IP addresses that can access sftp (list)
#       Default: ['0.0.0.0']
# - manage_selinux - whether or not to manage the selinux ports
#       Default: look in hiera or false
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::sftp':
#     client_ips         => ['10.0.250.1'],
#   }
#
# [*Hiera YAML*]
#   profile::sftp:port: 12000
#   profile::sftp::client_ips: [10.0.250.1]
#
class profile::sftp::server (
  $port           = $profile::sftp::port,
  $client_ips     = ['0.0.0.0'],
  $manage_selinux = hiera('selinux_enabled', false),
) inherits profile::sftp {

# cgeka/sftp does all the heavy lifting for config
  class { '::proftpd':
    manage_proftpd_conf => true,
  }

  proftpd::instance::sftp {'SFTP':
    port   => $port,
    logdir => '/var/log',
  }

  # TODO: Manage User/Groups?

  ## Firewall stuff
  if str2bool($::settings::storeconfigs) {
    # Let other systems connect outbound to us.
    @@firewall { "200 OUTPUT allow sftp server access at ${::ipaddress}:${port}/tcp":
      dport       => $port,
      proto       => 'tcp',
      action      => 'accept',
      chain       => 'OUTPUT',
      destination => $::ipaddress,
      tag         => "fw_${::environment}_${::client}_${::app_tier}_${::app_name}_sftp_out_to_sftp_server",
    }

    # Allow inbound connections from our discovered clients.
    Firewall <<| tag == "fw_${::environment}_${::client}_${::app_tier}_${::app_name}_sftp_in_from_sftp_clients" |>>

    # hosts entry for SFTP CLIENT to find SFTP SERVER
    @@host { $::fqdn:
      ensure       => present,
      host_aliases => 'sftp.puppet',
      comment      => 'profile::sftp::server',
      ip           => $::ipaddress,
      tag          => "host_${::environment}_${::client}_${::app_tier}_${::app_name}_sftp_server",
    }
  }

  # Manual firewall rules
  $fw_client_ips = suffix($client_ips, '||SFTP-Access')
  ensure_resource(profile::firewall::fwrule, $fw_client_ips, {
    direction => 'INPUT',
    port      => $port,
    proto     => 'tcp',
  })

## SELinux Stuff
  if $manage_selinux {
    selinux::boolean {'ftpd_full_access':
      ensure => 'on', #FIXME: This should not need to be set, but we are on a time crunch
    }

    # NOTE: This only partially works. We had to set the ftpd_full_access boolean because
    #  these directories are still not accessible due to the way the selinux policy was
    #  written. We may have to come up with a new policy that includes "directories" for
    #  the ftpd_etc_t. (FIXME)
    selinux::fcontext{'set-ftpd-etc-context':
      context             => 'ftpd_etc_t',
      pathname            => '/etc/proftpd(/.*)?',
      restorecond_path    => '/etc/proftpd',
      restorecond_recurse => true,
    }

    # FIXME: There is not currently a way to "move" a port from ssh_port_t to ftp_port_t
    # This will require manual intervention: (change the -a to -m on the failing command)
    selinux::port { 'allow-sftp-port-ftpd-selinux':
      context  => 'ftp_port_t',
      protocol => 'tcp',
      port     => $port,
    }
  }

}

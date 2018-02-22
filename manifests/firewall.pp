#
# Class: profile::firewall
# Purpose: Handle setting up the firewall
# Parameters:
#   - firewall_enabled - boolean - Enable firewall? (Default: false)
#   - purge - boolean - Purge Unamanged Rules (Default: true)
#       -- NOTE: Set to false for fail2ban setups
#   - rules - hash - Hash of firewall rules to add (Default: {})
#   - drop_nolog - array - List of ports to drop without logging (Default: [])
#   - ignore_chains - array - List of iptables chains to ignore (purge false)
#       (Default ['fail2ban-SSH:filter:IPv4']
#   - admin_ips - list of administrative IP addresses, can be used by other
#       profiles - Default: undef (which results in "any" IP allowed in)
#
class profile::firewall (
  $firewall_enabled = true,
  $purge = true,
  $rules = {},
  $drop_nolog = [],
  $ignore_chains = ['fail2ban-SSH:filter:IPv4'],
  $admin_ips = [],
) {

  validate_bool($firewall_enabled)
  validate_bool($purge)
  validate_hash($rules)
  validate_array($drop_nolog)

  # Find the "ensure" value for ::firewall
  $firewall_ensure = $firewall_enabled ? {
    true  => 'running',
    default => 'stopped'
  }

  # This handles turning *off* the firewall if its enabled by default
  # but we have firewall_enabled = false
  class { '::firewall':
    ensure => $firewall_ensure,
  }

  if $firewall_enabled {

    # The following should be in "site.pp" probably
    resources { 'firewall':
      purge => $purge,
    }

    # The following should be in "site.pp" probably
    Firewall {
      require => Class['profile::firewall::pre', 'profile::firewall::prev6'],
      before  => Class['profile::firewall::post', 'profile::firewall::postv6'],
    }

    # Allow for "fail2ban" and puppet to cooperate (a little)
    firewallchain { 'INPUT:filter:IPv4':
      purge  => true,
      ignore => [
        # ignore the fail2ban jump rule
        '-j fail2ban-.*',
        # ignore any rules with "ignore" (case insensitive) in the comment in the rule
        '--comment "[^"]*(?i:ignore)[^"]*"',
      ],
    }

    # Probable redundancy - IPv6 support
    firewallchain { 'INPUT:filter:IPv6':
    purge  => true,
    ignore => [
        '-j fail2ban-.*',
        '--comment "[^"]*(?i:ignore)[^"]*"',
        ]
    }

    # Allow for "ignored" rules in OUTPUT with purge true
    firewallchain { 'OUTPUT:filter:IPv4':
      purge  => true,
      ignore => [
        # ignore any rules with "ignore" (case insensitive) in the comment in the rule
        '--comment "[^"]*(?i:ignore)[^"]*"',
      ],
    }

    # Probable redundancy - IPv6 support
    firewallchain { 'OUTPUT:filter:IPv6':
    purge  => true,
    ignore => [
        '-j fail2ban-.*',
        '--comment "[^"]*(?i:ignore)[^"]*"',
      ]
    }

    firewallchain { $ignore_chains:
      purge  => false,
    }

    include ::profile::firewall::pre
    include ::profile::firewall::post

    include ::profile::firewall::prev6
    include ::profile::firewall::postv6

    # Create data defined firewall rules (safely handles empty hash)
    create_resources(firewall, $rules)

    if count($drop_nolog) > 0 {
        # Drop No Log Rules - to keep firewall logs quieter
        firewall { '050 - INPUT drop NoLog TCP ports':
        chain  => 'INPUT',
        action => 'drop',
        dport  => $drop_nolog,
        proto  => 'tcp',
        }

        firewall { '050 - INPUT drop NoLog UDP ports':
        chain  => 'INPUT',
        action => 'drop',
        dport  => $drop_nolog,
        proto  => 'udp',
        }

        firewall { '050 - INPUT drop NoLog TCP ports IPv6':
        chain    => 'INPUT',
        action   => 'drop',
        dport    => $drop_nolog,
        proto    => 'tcp',
        provider => 'ip6tables',
        }

        firewall { '050 - INPUT drop NoLog UDP ports IPv6':
        chain    => 'INPUT',
        action   => 'drop',
        dport    => $drop_nolog,
        proto    => 'udp',
        provider => 'ip6tables',
        }

    }

  } # if firewall enabled
}

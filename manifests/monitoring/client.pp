#
# === Class: profile::monitoring::client
#
# Setup Monitoring Client
#
# === Parameters
#
# [*type*]
#   Type of monitoring client to install.
#   (String) Defaults to 'nrpe'
#     Acceptable Values:
#       * nrpe
#
# [*servers*]
#   A list of monitoring servers for firewall purposes (in lieu of exported resources)
#   (String or Array) Defaults to undef.
#
# [*port_override*]
#   Monitoring Client Port override
#   (String) Default to appropriate value for $type
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::monitoring::client':
#     $servers => '10.1.2.3',
#   }
#
# [*Hiera YAML*]
#   profile::monitoring::client::servers: '10.1.2.3'
#
class profile::monitoring::client (
  $type = 'nrpe',
  $servers = undef,
  $port_override = undef,
) inherits profile::monitoring {

  # Validate
  validate_re($type, ['^nrpe$'], "Type must be 'nrpe'.  Found: ${type}")
  if is_string($servers) {
    validate_string($servers)
  } else {
    validate_array($servers)
  }

  # If we haven't failed validation above, go ahead and include the type
  include "::profile::monitoring::client::${type}"

}

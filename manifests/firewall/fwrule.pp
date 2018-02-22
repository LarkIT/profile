#
# Class: profile::firewall::fwrule
# Purpose: Due to Puppet's lack of iteration features, there's a use
#          case where we need to potentially define a rule for multiple hosts.
#
# === Parameters
#
# [*port*]
#   Port for rule (note that ranges should be 137-139 format)
#   (String or Array) Default undef
#
# [*proto*]
#   protocol for firewall rule (can be set to undef)
#   (String) Default: 'tcp'
#
# [*direction*]
#   Direction for firewall rule, can only be 'INPUT' or 'OUTPUT'
#   (String) Default 'OUTPUT'
#
# [*action*]
#   Action for firewall rule (passed directly to firewall type)
#   (String) Default 'accept'
#
#
#
#  NOTE: $name must be unique, you may want to use suffix() to add a desc slug on
#     For Example:
#       $fw_admin_ips = suffix($admin_ips, '||special-admin-ui')
#       ensure_resource(profile::firewall::fwrule, any2array($fw_admin_ips), {
#         direction => 'INPUT',
#         port      => $admin_port,
#         proto     => 'tcp',
#       })
#
define profile::firewall::fwrule (
  $port = undef,
  $proto = 'tcp',
  $direction = 'OUTPUT',
  $action = 'accept',
  $provider = undef,
) {

  # Validate

  # Lets let $port validation pass through to stdlib::firewall for now
  validate_string($proto)
  validate_string($direction)
  validate_string($action)

  # validate $name
  if $name =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(\/\d+)?$/ { # looks like an IP
    $ip = $name
    $slug = 'NO-DESC'
  } elsif $name =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(\/\d+)?)\|\|(.*)$/ { # has IP and desc
    $ip = $1
    $slug = $3
  } else {
    fail("${module_name}::fwrule requires the name to be IP(/mask)(||description).  Received '${name}'")
  }


  if is_array($port) {
    $port_title = join($port,',')
  } else {
    $port_title = $port
  }

  case $direction {
    'OUTPUT': {
      $source = undef
      $destination = $ip
      $rule_title = "200 ${direction} ${action} ${slug} ${port_title}/${proto} to ${destination}"
    }
    'INPUT': {
      $source = $ip
      $destination = undef
      $rule_title = "200 ${direction} ${action} ${slug} ${port_title}/${proto} from ${source}"
    }
    default: {
      fail("${module_name} requires ${direction} to be 'INPUT' or 'OUTPUT'")
    }
  }

  firewall { $rule_title:
    source      => $source,
    destination => $destination,
    dport       => $port,
    proto       => $proto,
    action      => $action,
    chain       => $direction,
    provider    => $provider,
  }
}

#
# === Class: profile::monitoring
#
# Setup Database - INHERIT CLASS
#  ### THIS CLASS DOESN'T DO ANYTHING
#  ### It just holds variables and settings
#  ### try monitoring::client or monitoring::server instead
#
#
# === Parameters
#
# [*monitor_tag*]
#   Monitoring Client tag override (for exported resources). May be used to
#   enable more than one monitoring server.
#   (String) Default to "default" :)
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::monitoring':
#     $tag    => 'SuperSpecialTag',
#   }
#
# [*Hiera YAML*]
#   profile::database::tag: SuperSpecialTag
#
class profile::monitoring (
  $monitor_tag       = 'DEFAULT',
) {
  # Validate
  validate_string($monitor_tag)

  ## AS NOTED, THIS CLASS DOES NOTHING BUT HOLD COMMON SETTINGS
}

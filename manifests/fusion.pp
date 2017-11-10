#
# === Class: profile::fusion
#
# Setup Fusion Server
#
# === Parameters
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::fusion': }
#
#
class profile::fusion
{
  include java
  include fusion

}

#
# Class: profile::ex_motd::params
# Purpose: Default motd for systems.  Better messages can come from Foreman or
# Hiera.
#
class profile::ex_motd::params {
  $message = 'Authorized Users Only.'
}

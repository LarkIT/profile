#
# Class: profile::selinux
# Purpose: Setup selinux
# Note:  We don't disabled SELinux completely.  The choices
#       we have are "true vs false," which we equate to "Enforcing
#       vs Permissive."
#
class profile::selinux (
  $booleans = {},
) {

  $mode_to_set = hiera('selinux_enabled',false) ? {
    true    => 'enforcing',
    false   => 'permissive',
    default => 'permissive',
  }

  class { '::selinux':
    mode => $mode_to_set,
  }
  
  validate_hash($booleans)
  create_resources('::selinux::boolean', $booleans)
}

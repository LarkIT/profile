#
# Class: profile::base::tuned
# Purpose: Ensure that tuned is loaded
# Configuration: Set via tuned parameters in hiera
#
class profile::base::tuned (
  $profile = undef,
  $source = undef,
) {

  if ($profile) {
    $_profile = $profile
  } else {
    # Lark IT Opinionated Default Profile
    $_profile = $::virtual ? {
      'physical' => 'throughput-performance',
      default    => 'throughput-performance',
      #default   => 'virtual-guest',  # OLD LARK DEFAULT
      #default   => 'balanced',       # System Default
    }
  }

  class{ '::tuned':
    profile => $_profile,
    source  => $source,
  }

}

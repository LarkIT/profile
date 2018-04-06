# Class: profile::base::ntp
#
# Purpose: Setup NSCD on a host and ensure it is running
#
#
class profile::base::nscd {
  include ::nscd
}

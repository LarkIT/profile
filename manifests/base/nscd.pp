# Class: profile::base::ntp
#
# Purpose: Setup NSCD on a host and ensure it is running
#
#
class profile::base::nscd {

  include ::nscd

  sensu::check {'nscd_running':
    handlers => [ 'default' ],
    interval => 180,
    command  => '/etc/sensu/plugins/check-process.rb -p "/usr/sbin/nscd" -c1 -w1',
  }
}

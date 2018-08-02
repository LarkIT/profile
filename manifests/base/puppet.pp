# Class: profile::base::puppet
#
# Purpose: Setup puppet on a host and monitor it
#
#
class profile::base::puppet {

  include ::puppet

  # Needed for the puppet-last-run check to allow the sensu user to access
  # the catalog yaml.  The path is hard coded for puppet 3.x, this will need
  # to be smarter to support puppet 4.x AIO install
  file { '/var/lib/puppet/':
    mode    => '0755',
  }
}

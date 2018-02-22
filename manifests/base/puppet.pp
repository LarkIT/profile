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

  # This is hard coded for puppet 3.x.  Will need to be modified for puppet 4.x AIO install
  sensu::check {'puppet-last-run':
    handlers => [ 'default' ],
    interval => 900,
    command  => '/etc/sensu/plugins/check-puppet-last-run.rb --summary-file /var/lib/puppet/state/last_run_summary.yaml',
  }
}

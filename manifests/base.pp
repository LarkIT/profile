# Base Profile
class profile::base {
#  include ::profile::auth
#  include ::profile::duplicity
#  include ::profile::monitoring::client
#  include ::profile::newrelic
#  include ::profile::selinux
#  include ::profile::ssh
#  include firewall
#  include profile::cloudwatch
#  include profile::squid_client
  include profile::base::puppet_agent
  include profile::base::smtp
#  include profile::monitoring::sensu_client
  include profile::ntp
#  include profile::pulp_client

  $packages=[ 'screen',
              'rpmconf',
              'vim-enhanced',
              'net-tools',
              'bind-utils',
              'oddjob-mkhomedir',
              'mlocate',
              'telnet',
              'unzip' ]

  package {$packages:
    ensure => latest,
  }
}

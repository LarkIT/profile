# Base Profile
class profile::base {
#  include ::profile::selinux
#  include ::profile::firewall
#  include ::profile::auth
#  include ::profile::ssh
#  include ::profile::duplicity
#  include ::profile::newrelic
#  include ::profile::monitoring::client
#  include ::profile::monitoring::sensu_client

  include profile::ntp
#  include profile::pulp_client
#  include profile::squid_client
  include profile::cloudwatch


  $packages=['screen','vim-enhanced','net-tools','bind-utils','oddjob-mkhomedir']

  package {$packages:
    ensure => latest,
  }
}

#
# === Class: profile::railsapp
#
# Setup Pulp Server
#
# === Parameters
#
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::railsapp': }
#
#
class profile::railsapp (
  Array $additional_packages = [],
  Array $additional_classes = [],
) {
include profile::pulp_client
  # Yes we know its bad
  $standard_railsapp_packages = [
  'nano',
  'git',
  'v8',
  'libxml2',
  'libxml2-devel',
  'libxslt',
  'libxslt-devel',
  'gcc-c++',
  'nodejs',
  'ImageMagick',
  'ImageMagick-devel',
  ]

  ensure_packages($standard_railsapp_packages)
  ensure_packages($additional_packages)
  include $additional_classes

  # LVM: DataDisk Mounts - please see hieradata/role/railsapp.yaml
  include ::lvm

  include ::swap_file
  include ::redis

#  include ::repos::passenger
  include ::rvm
  include ::host_railsapp

  ensure_packages($additional_packages)


  # Firewall
  firewall { '100 INPUT allow http(s) from all':
    dport  => [ '80', '443' ],
    proto  => 'tcp',
    action => 'accept',
    chain  => 'INPUT',
  }

  firewall { '100 INPUT allow http(s) from all IPv6':
    dport    => [ '80', '443' ],
    proto    => 'tcp',
    action   => 'accept',
    chain    => 'INPUT',
    provider => 'ip6tables',
  }

  # Monitoring - DISABLED FOR NOW
  $monitor = pick($host_railsapp::process_mon, 'nginx: master process')


}

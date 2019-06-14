#
# === Class: profile::rails
#
# Setup Lark/CK Webapp server, using Ruby, RVM, and a Postgresql client.
#
# === Parameters
#
# [*additional_packages*]
#   A list of additional packages to install on the host.
#   (Array) Defaults to [].
#
# [*additional_classes*]
#   A list of additional classes to include this profile.
#   (Array) Defaults to [].
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::rails':
#     $additional_packages => [ 'package1', 'package2', ],
#     $additional_classes  => [ 'class1', 'class2', ],
#   }
#
# [*Hiera YAML*]
#   profile::rails::additional_packages:
#     - 'packagename1'
#     - 'packagename2'
#   profile::rails::additional_classes:
#     - 'class1'
#     - 'class2'
#

class profile::rails (
  $additional_packages = [],
  $additional_classes  = [],
  $additional_fw_rules = {},
  $enable_letsencrypt = false,
  $letsencrypt_config = {},
) {

  validate_array($additional_packages)
  validate_array($additional_classes)

  # Additional Classes for this module - this may change forms in the future
  include $additional_classes
  ensure_packages($additional_packages)

  include ::repos::passenger
  include ::rvm
  include ::host_railsapp
  if $enable_letsencrypt {
    if $trusted['pp_environment'] == 'stage' {
      $webroot_subdirectory = 'staging'
    }
    if ($trusted['pp_environment'] == 'production') or ($trusted['pp_environment'] == 'aspire') {
      $webroot_subdirectory = 'production'
    }
    class{ 'letsencrypt':
      * => $letsencrypt_config,
    }
    letsencrypt::certonly { $::fqdn:
      domains              => [$::fqdn],
      plugin               => 'webroot',
      webroot_paths        => ["/web/railsapp/${webroot_subdirectory}/current/public"],
      additional_args      => ['--expand --non-interactive'],
      cron_success_command => '/bin/systemctl restart nginx.service',
      manage_cron          => true,
    }
  }

  # No matter what... we want to allow http in...
  firewall { '100 INPUT allow http(s) from anyone':
    dport  => [ '80', '443' ],
    proto  => 'tcp',
    action => 'accept',
    chain  => 'INPUT',
  }

  firewall { '100 INPUT allow http(s) from anyone IPv6':
    dport    => [ '80', '443' ],
    proto    => 'tcp',
    action   => 'accept',
    chain    => 'INPUT',
    provider => 'ip6tables'
  }

  # Temporary until can be narrowed down for what really needs it...
  firewall { '200 OUTPUT allow ssh outbound':
    dport  => '22',
    proto  => 'tcp',
    action => 'accept',
    chain  => 'OUTPUT',
  }

  # Additional (hiera) firewall rules
  create_resources(firewall, $additional_fw_rules)

  $monitor = pick($host_railsapp::process_mon, 'nginx: master process')
  sensu::check {'webserver running':
    handlers => [ 'default' ],
    interval => 180,
    command  => "/etc/sensu/plugins/check-process.rb -p \"${monitor}\" -C1 -W1 -u root",
  }

}

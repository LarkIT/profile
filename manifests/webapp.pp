#
# === Class: profile::webapp
#
# Setup Lark/CK Webapp server
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
#   class { 'profile::webapp':
#     $additional_packages => [ 'package1', 'package2', ],
#     $additional_classes  => [ 'class1', 'class2', ],
#   }
#
# [*Hiera YAML*]
#   profile::webapp::additional_packages:
#     - 'packagename1'
#     - 'packagename2'
#   profile::webapp::additional_classes:
#     - 'class1'
#     - 'class2'
#
class profile::webapp (
  $additional_packages = [],
  $additional_classes  = [],
) {


  validate_array($additional_packages)
  validate_array($additional_classes)

  # Additional Classes for this module - this may change forms in the future
  include $additional_classes
  ensure_packages($additional_packages)

  include ::webapp
  include ::selinux

  # No matter what... we want to allow http in...
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

  # Temporary until can be narrowed down for what really needs it...

  firewall { '200 OUTPUT allow ssh outbound':
    dport  => '22',
    proto  => 'tcp',
    action => 'accept',
    chain  => 'OUTPUT',
  }

  firewall { '200 OUTPUT allow ssh outbound IPv6':
    dport    => '22',
    proto    => 'tcp',
    action   => 'accept',
    chain    => 'OUTPUT',
    provider => 'ip6tables',
  }

  if str2bool($::selinux) {
    if !defined(Selboolean['httpd_can_network_connect']) {
      selboolean { 'httpd_can_network_connect':
        persistent => true,
        value      => on,
      }
    }
  }
}

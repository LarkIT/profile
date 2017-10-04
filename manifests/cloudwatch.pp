#
# === Class: profile::cloudwatch
#
# Setup cloudwatch client
#
# === Parameters
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::cloudwatch': }
#
#

class profile::cloudwatch (
  $manage_proxy_conf    = true,
  $install_python_devel = true,
  $additional_packages  = $profile::cloudwatch::additional_packages,
  $enable_cloudwatch    = true,
) {
  
  if $enable_cloudwatch == true {
    class { '::cloudwatchlogs':
      logs => lookup('profile::cloudwatch::logs', Hash, deep),
    }

    if ($manage_proxy_conf) {
      include profile::cloudwatch::proxy
     }

    if ($install_python_devel) {
      ensure_packages($additional_packages)
    }
  }
}

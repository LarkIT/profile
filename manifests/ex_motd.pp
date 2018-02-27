#
# Class: profile::ex_motd
# Purpose: Setup /etc/motd on systems per company policy.
#
class profile::ex_motd (
  $message = $profile::ex_motd::params::message
) inherits profile::ex_motd::params {

  validate_string($message, 'dummyval')

  file { '/etc/motd':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('profile/ex_motd/motd.erb'),
  }
}

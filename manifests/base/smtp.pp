# Class profile::base::smtp
#
# Part of the base profile to configure SMTP
#
#
class profile::base::smtp (
  $root_redirect = undef,
  $smtp_relays   = [ '0.0.0.0/0' ]
){

  include ::postfix

  $_smtp_relays = suffix(any2array($smtp_relays), '||SMTP')
  ensure_resource(profile::firewall::fwrule, $_smtp_relays, {
    direction => 'OUTPUT',
    port      => [25, 465, 587],
    proto     => 'tcp',
  })

  if $root_redirect {
    mailalias { 'root':
      ensure    => present,
      recipient => $root_redirect,
      notify    => Class['postfix::newaliases'],
    }
  }
}

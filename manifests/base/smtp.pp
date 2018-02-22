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
  include ::profile::monitoring::sensu_client

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

  sensu::check { 'postfix_running':
    handlers => 'default',
    command  => '/etc/sensu/plugins/check-process.rb -p postfix',
    interval => 600,
  }

  sensu::check { 'mailq':
    handlers => 'default',
    command  => '/etc/sensu/plugins/check-mailq.rb -w 10 -c 30',
    interval => 600,
  }

}

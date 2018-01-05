# Class: profile::letsencrypt
#
# Fetches certificates for $domains
#
#
class profile::letsencrypt (
  $service,
  $domains = [$::fqdn],
  $config  = {},
){

  validate_array($domains)

  class{ 'letsencrypt':
    * => $config,
  }

  letsencrypt::certonly { $::fqdn:
    domains              => $domains,
    additional_args      => [ '--expand --non-interactive' ],
    cron_before_command  => "/bin/systemctl stop ${service}.service",
    cron_success_command => "/bin/systemctl reload ${service}.service",
    manage_cron          => true,
  }
}
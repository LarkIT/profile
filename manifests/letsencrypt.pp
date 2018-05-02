# Class: profile::letsencrypt
#
# Fetches certificates for $domains
#
#
class profile::letsencrypt (
  $service = 'httpd',
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
    cron_success_command => "/bin/systemctl reload ${service}.service",
    manage_cron          => true,
  }
}

# Class: profile::letsencrypt
#
# Fetches certificates for $domains
#
#
class profile::letsencrypt (
  $service              = 'httpd',
  $domains              = [$::fqdn],
  $config               = {},
  $manage_cron          = true,
  $cron_before_command = "/bin/systemctl stop ${service}.service",
  $cron_success_command = "/bin/systemctl reload ${service}.service",
){

  validate_array($domains)

  class{ 'letsencrypt':
    * => $config,
  }

  letsencrypt::certonly { $::fqdn:
    domains              => $domains,
    additional_args      => [ '--expand --non-interactive' ],
    cron_before_command  => $cron_before_command,
    cron_success_command => $cron_success_command,
    manage_cron          => $manage_cron,
  }
}

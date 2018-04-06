# Class: profile::letsencrypt
#
# Fetches certificates for $domains
#
#
class profile::letsencrypt (
  $service = 'httpd',
  $domains = [$::fqdn],
  $config  = {},
  $plugin  = 'standalone',
  $webroot_paths = [],
){

  validate_array($domains)

  class { 'letsencrypt':
    *     => $config,
    email =>  'lark-systems@lark-it.com',
  }

  letsencrypt::certonly { $::fqdn:
    domains              => $domains,
    plugin               => $plugin,
    webroot_paths        => $webroot_paths,
    additional_args      => [ '--expand --non-interactive' ],
    cron_before_command  => "/bin/systemctl stop ${service}.service",
    cron_success_command => "/bin/systemctl reload ${service}.service",
    manage_cron          => true,
  }
}

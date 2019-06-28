class profile::letsencrypt_rails (
  $service              = 'nginx',
  $domains               = [$::fqdn],
  $config               = {},
  $manage_cron          = true,
  $cron_success_command = "/bin/systemctl start ${service}.service",
){
  if $trusted['extensions']['pp_environment'] == 'stage' {
     $webroot_subdirectory = 'staging'
  }
  if ($trusted['extensions']['pp_environment'] == 'production') or ($trusted['extensions']['pp_environment'] == 'aspire') {
    $webroot_subdirectory = 'production'
  }
  class{ 'letsencrypt':
    * => $config,
  }
  letsencrypt::certonly { $::fqdn:
    domains              => $domains,
    plugin               => 'webroot',
    webroot_paths        => ["/web/railsapp/${webroot_subdirectory}/current/public"],
    additional_args      => ['--expand --non-interactive'],
    cron_success_command => $cron_success_command,
    manage_cron          => $manage_cron
  }
}



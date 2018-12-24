# === Class: profile::monitoring::sensu_client
#
# Setup / Install Sensu Client software
#
class profile::monitoring::sensu_client (
  $rabbitmq_client_cert = undef,
  $rabbitmq_client_key  = undef,
  $rabbitmq_server      = undef,
  $checks               = {},
  $mem_warn             = 85,
  $mem_crit             = 95,
  $swap_warn            = 50,
  $swap_crit            = 75,
  $disk_warn            = 85,
  $disk_crit            = 95,
  $purge_sensu_checks   = true,
) {

  include ::repos::sensu
  include ::sensu

  create_resources(sensu::check, $checks)

  file { '/etc/sensu/conf.d/cert.pem':
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0440',
    content => $rabbitmq_client_cert,
    require => Class['sensu::package'],
    notify  => Class['sensu::client'],
  }

  file { '/etc/sensu/conf.d/key.pem':
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0440',
    content => $rabbitmq_client_key,
    require => Class['sensu::package'],
    notify  => Class['sensu::client'],
  }

  # Allow inbound connections.
  Firewall <<| tag == 'ptag_sensu_server' |>>

  if $rabbitmq_server {
    firewall { "200 OUTPUT allow sensu/rabbitmq ports tcp at ${rabbitmq_server}:5671":
      dport       => '5671',
      proto       => 'tcp',
      action      => 'accept',
      chain       => 'OUTPUT',
      destination => $rabbitmq_server,
    }
  }

  sensu::subscription { 'all': }

  if $::memory { # facter 3
    # Total system bytes * 80% / 1024 / 1024 to convert to MB
    $wmem = inline_template("<%= ((@memory['system']['total_bytes'].to_i * (100 - Integer(@mem_warn))/100)/1024/1024).round %>").scanf("%i")[0]
    $cmem = inline_template("<%= ((@memory['system']['total_bytes'].to_i * (100 - Integer(@mem_crit))/100)/1024/1024).round %>").scanf("%i")[0]
    if $::memory['swap'] {
      $wswap = inline_template("<%= (@memory['swap']['total_bytes'].to_i * Integer(@swap_warn)/100/1024/1024).round %>").scanf("%i")[0]
      $cswap = inline_template("<%= (@memory['swap']['total_bytes'].to_i * Integer(@swap_crit)/100/1024/1024).round %>").scanf("%i")[0]
    }
  } else { # facter 2
    $wmem = inline_template('<%= (@memorysize_mb.to_i * (100 - Integer(@mem_warn))/100).round %>').scanf("%i")[0]
    $cmem = inline_template('<%= (@memorysize_mb.to_i * (100 - Integer(@mem_crit))/100).round %>').scanf("%i")[0]
    if $::memory['swap'] {
      $wswap = inline_template('<%= (@swapsize_mb.to_i * Integer(@swap_warn)/100).round %>').scanf("%i")[0]
      $cswap = inline_template('<%= (@swapsize_mb.to_i * Integer(@swap_crit)/100).round %>').scanf("%i")[0]
    }
  }

  sensu::check { 'memory':
    handlers     => [ 'default' ],
    command      => "/etc/sensu/plugins/check-memory.sh -w ${wmem} -c ${cmem}",
    subscribers  => [ 'all' ],
    interval     => 300,
    occurrences  => 10,
  }

  if $::memory['swap'] {
    if $wswap > 0 and $cswap > 0 {
      sensu::check { 'swap':
        handlers    => [ 'default' ],
        command     => "/etc/sensu/plugins/check-swap.sh -w ${wswap} -c ${cswap}",
        subscribers => [ 'all' ],
        interval    => 300,
        occurrences => 10,
      }
    }
  }

  package { 'sensu-plugins-disk-checks':
    ensure   => present,
    provider => sensu_gem,
  }

  package { 'sensu-plugins':
    ensure => present,
  }

  sensu::check { 'disk-free':
    handlers    => [ 'default' ],
    command     => "/opt/sensu/embedded/bin/check-disk-usage.rb -t ext3,ext4,xfs -w ${disk_warn} -c ${disk_crit}",
    subscribers => [ 'all' ],
    interval    => 3600,
    require     => Package['sensu-plugins-disk-checks'],
  }

  sensu::check { 'cpu':
    handlers    => 'default',
    command     => '/etc/sensu/plugins/check-cpu.rb --sleep 20',
    interval    => 600,
    occurrences => 10,
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

  sensu::check {'puppet-last-run':
    handlers => [ 'default' ],
    interval => 900,
    command  => 'sudo /etc/sensu/plugins/check-puppet-last-run.rb',
  }

  file_line { 'sudo_rule_sensu_puppet_check':
    path => '/etc/sudoers',
    line => '%sensu  ALL=NOPASSWD: /etc/sensu/plugins/check-puppet-last-run.rb',
  }
}

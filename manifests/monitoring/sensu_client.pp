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
    notify  => Class['sensu::client::service'],
  }

  file { '/etc/sensu/conf.d/key.pem':
    owner   => 'sensu',
    group   => 'sensu',
    mode    => '0440',
    content => $rabbitmq_client_key,
    require => Class['sensu::package'],
    notify  => Class['sensu::client::service'],
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
    occurrences  => 6,
  }

  if $::memory['swap'] {
    if $wswap > 0 and $cswap > 0 {
      sensu::check { 'swap':
        handlers    => [ 'default' ],
        command     => "/etc/sensu/plugins/check-swap.sh -w ${wswap} -c ${cswap}",
        subscribers => [ 'all' ],
        interval    => 300,
        occurrences => 2,
      }
    }
  }

  sensu::check { 'disk-free':
    handlers    => [ 'default' ],
    command     => "/etc/sensu/plugins/check-disk-usage.rb -t ext3,ext4,xfs -w ${disk_warn} -c ${disk_crit}",
    subscribers => [ 'all' ],
    interval    => 3600,
  }

  sensu::check { 'cpu':
    handlers    => 'default',
    command     => '/etc/sensu/plugins/check-cpu.rb --sleep 20',
    interval    => 600,
    occurrences => 2,
  }
}

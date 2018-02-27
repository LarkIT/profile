#
# === Class: profile::logstash
#
# Setup LogStash Server
# LogStash also needs elasticsearch
#
# === Parameters
#
# - cluster_name - elasticsearch cluster name (string) - default: 'logstash'
# - admin_ips - IP addresses that can access admin interface (list) - default []
# - syslog_client_ips - IP addresses that can (statically) access log port (list) - default []
# - syslog_port - Port(s) that will run syslogd (currently only used for firewall rules) - list - Default: 9514
# - web_port - Port(s) that will run the web interface (currently only used for firewall rules - list - Default: 9292
# - lumberjack_port - TCP port for lumberjack service - default: 9500
# - lumberjack_ssl_key - unencrypted SSL Key for lumberjack
# - lumberjack_ssl_cert - unencrypted SSL Key for lumberjack
# - output_debug - whether or not to send debug to stdout (boolean) - default false
# - logstash_configs - additional Configfile templates (see logstash docs) - default {}
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::logstash':
#     admin_ips         => ['10.0.250.1'],
#     syslog_client_ips => ['10.0.250.101', '10.0.250.102'],
#   }
#
# [*Hiera YAML*]
#   profile::logstash::admin_ips: [10.0.250.1]
#   profile::logstash::syslog_client_ips:
#     - 10.0.250.101
#     - 10.0.250.102
#     - 10.0.250.103
#
class profile::logstash (
  $cluster_name = 'logstash',
  $admin_ips = $profile::firewall::admin_ips,
  $syslog_client_ips = [],
  $syslog_port = 9514,
  $web_port = 9292,
  $es_port = 9200,
  $lumberjack_port = 9500,
  $lumberjack_ssl_key = undef,
  $lumberjack_ssl_cert = undef,
  $output_debug = false,
  $logstash_configs = {}
) {

# *** USING EMBEDDED ElasticSearch ***
#  # Java is needed for ES
#  include ::java
#
#  # SWAP!?
  include ::swap_file
#
#  # ElasticSearch
#  # Some defaults, simple one host, all in one install
#  $es_instance = "${cluster_name}-es"
#  $es_config_hash = {
#      'cluster.name'                         => $cluster_name,
#      'discovery.zen.ping.multicast.enabled' => false,
#      'discovery.zen.ping.unicast.hosts'     => ['localhost'],
#      'script.disable_dynamic'               => true,
#      'network.host'                         => '127.0.0.1',
#  }
#  $es_init_defaults = {
#    'MAX_OPEN_FILES' => '65536',
#  }
#  include ::elasticsearch
#  elasticsearch::instance { $es_instance:
#    config        => $es_config_hash,
#    init_defaults => $es_init_defaults,
#  }
#

  ## LogStash -- Enable embedded web server
  ## NOTE: This may be deprecated, but its simple for now.
  $ls_init_defaults = {
    'LS_OPTS' => "\" -- web --port ${web_port}\"",
  }

  class { '::logstash':
    manage_repo   => true,
    repo_version  => '1.4',
    java_install  => true,
    init_defaults => $ls_init_defaults,
  }

  ## Lumberjack is the "logstash-forwarder" port
  ## - special requirements
  if ( $lumberjack_port != undef
      and $lumberjack_ssl_key != undef
      and $lumberjack_ssl_cert != undef ) {

    # These filenames will be used in the config erb template too
    $lumberjack_sslcert_file = '/etc/pki/tls/certs/lumberjack.crt'
    $lumberjack_sslkey_file = '/etc/pki/tls/private/lumberjack.key'

    file { $lumberjack_sslcert_file:
      ensure  => file,
      owner   => 'root',
      group   => 'logstash',
      mode    => '0640',
      content => $lumberjack_ssl_cert,
      notify  => Class['::logstash::service'],
      require => Class['::logstash::package'],
    }

    file { $lumberjack_sslkey_file:
      ensure  => file,
      owner   => 'root',
      group   => 'logstash',
      mode    => '0640',
      content => $lumberjack_ssl_key,
      notify  => Class['::logstash::service'],
      require => Class['::logstash::package'],
    }

    logstash::configfile { 'input_lumberjack':
      content => template('profile/logstash/input_lumberjack.erb'),
      order   => 11,
    }
  }

  # Patterns
  logstash::patternfile { 'apache':
    source => 'puppet:///modules/profile/logstash/apache',
  }

  # Config files at the end (before firewall)
  $standard_logstash_configs = {
    'input_syslog' => {
      content      => template('profile/logstash/input_syslog.erb'),
      order        => 10,
    },
    'filter_syslog' => {
      content       => template('profile/logstash/filter_syslog.erb'),
      order         => 50,
    },
    'filter_apache' => {
      content       => template('profile/logstash/filter_apache.erb'),
      order         => 50,
    },
    'filter_monolog' => {
      content       => template('profile/logstash/filter_monolog.erb'),
      order         => 50,
    },
    'output_es' => {
      content   => template('profile/logstash/output_es.erb'),
      order     => 90,
    },
  }
  $effective_configs = merge($logstash_configs, $standard_logstash_configs)
  create_resources('::logstash::configfile', $effective_configs)

  if ($output_debug) {
    logstash::configfile { 'output_debug':
      content =>  template('profile/logstash/output_debug.erb'),
      order   => 99,
    }
  }

  # Firewall stuff
  if str2bool($::settings::storeconfigs) {
    # Let other systems connect outbound to us.
    @@firewall { "200 OUTPUT allow log server tcp at ${::ipaddress}:${syslog_port}":
      dport       => [$syslog_port, $lumberjack_port],
      proto       => 'tcp',
      action      => 'accept',
      chain       => 'OUTPUT',
      destination => $::ipaddress,
      tag         => "ptag_${::environment}_out_clients_to_syslog_server",
    }

    @@firewall { "200 OUTPUT allow log server tcp at ${::ipaddress}:${syslog_port} - IPv6":
      dport       => [$syslog_port, $lumberjack_port],
      proto       => 'tcp',
      action      => 'accept',
      chain       => 'OUTPUT',
      destination => $::ipaddress,
      tag         => "ptag_${::environment}_out_clients_to_syslog_server",
      provider    => 'ip6tables',
    }

    # Allow inbound connections.
    Firewall <<| tag == "ptag_${::environment}_in_clients_to_syslog_server" |>>
  }

  # Manual firewall rule overrides
  $fw_syslog_client_ips = suffix($syslog_client_ips, '||syslog-client')
  ensure_resource(profile::firewall::fwrule, any2array($fw_syslog_client_ips), {
    direction => 'INPUT',
    port      => [$syslog_port, $lumberjack_port],
    proto     => 'tcp',
  })

  # Admin Firewall Rules (currently only accepting hard coded rules)
  $fw_admin_ips = suffix($admin_ips, '||logstash-webui')
  ensure_resource(profile::firewall::fwrule, any2array($fw_admin_ips), {
    direction => 'INPUT',
    port      => [$web_port, $es_port],
    proto     => 'tcp',
  })

}

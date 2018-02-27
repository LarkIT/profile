#
# === Class: profile::graylog2
#
# Setup GrayLog2 Server
# GrayLog 2 also needs redis and elasticsearch
#
# === Parameters
#
# - secret - graylog2 secret (string >64 chars) - no default
# - root_password_sha2 - graylog2 root pass (string) - no default (sha256sum)
# - cluster_name - elasticsearch cluster name (string) - default: 'graylog2'
# - admin_ips - IP addresses that can access admin interface (list) -
#      default profile::firewall::admin_ips
# - syslog_client_ips - IP addresses that can (statically) access log port (list) - default []
# - syslog_port - Port(s) that will run syslogd (currently only used for firewall rules) - list - Default: 9514
# - web_port - Port(s) that will run the web interface (currently only used for firewall rules - list - Default: 9000
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::graylog2':
#           secret             => 'AReallyLongStringSoTheWebPartCanTalkTotheBackend',
#           root_password_sha2 => 'Sha2HashedPasswordIguess',
#   }
#
# [*Hiera YAML*]
#   profile::graylog2::secret: AReallyLongStringSoTheWebPartCanTalkTotheBackend
#   profile::graylog2::root_password_sha2: Sha2HashedPasswordIguess
#
class profile::graylog2 (
  $secret,
  $root_password_sha2,
  $cluster_name = 'graylog2',
  $admin_ips = profile::firewall::admin_ips,
  $syslog_client_ips = [],
  $syslog_port = 9514,
  $web_port = 9000,
) {

  # Java is needed for ES
  include ::java

  # SWAP!
  include ::swap_file

  # ElasticSearch
  # Some defaults, simple one host, all in one install
  $es_instance = "${cluster_name}-es"
  $config_hash = {
      'cluster.name'                         => $cluster_name,
      'discovery.zen.ping.multicast.enabled' => false,
      'discovery.zen.ping.unicast.hosts'     => ['localhost'],
      'script.disable_dynamic'               => true,
      'network.host'                         => '127.0.0.1',
  }
  $init_defaults = {
    'MAX_OPEN_FILES' => '65536',
  }
  include ::elasticsearch
  elasticsearch::instance { $es_instance:
    config        => $config_hash,
    init_defaults => $init_defaults,
  }

  # MongoDB
  include ::mongodb::globals
  include ::mongodb::server
  include ::mongodb::client

  include ::graylog2::repo

  class { '::graylog2::server':
    password_secret                                    => $secret,
    root_password_sha2                                 => $root_password_sha2,
    elasticsearch_cluster_name                         => $cluster_name,
    elasticsearch_discovery_zen_ping_multicast_enabled => false,
    elasticsearch_discovery_zen_ping_unicast_hosts     => 'localhost:9300',
    require                                            => [
      Elasticsearch::Instance[$es_instance],
      Class['mongodb::server'],
      Class['graylog2::repo'],
    ],
  }

  class { '::graylog2::web':
    application_secret => $secret,
    require            => Class['graylog2::server'],
  }

  if str2bool($::settings::storeconfigs) {
    # Let other systems connect outbound to us.
    @@firewall { "200 OUTPUT allow log server tcp at ${::ipaddress}:${syslog_port}":
      dport       => $syslog_port,
      proto       => 'tcp',
      action      => 'accept',
      chain       => 'OUTPUT',
      destination => $::ipaddress,
      tag         => "ptag_${::environment}_${::client}_${::app_tier}_out_clients_to_syslog_server",
    }
    # Allow inbound connections.
    Firewall <<| tag == "ptag_${::environment}_${::client}_${::app_tier}_in_clients_to_syslog_server" |>>
  }

  # Manual firewall rule overrides
  ensure_resource(profile::firewall::fwrule, any2array($syslog_client_ips), {
    direction => 'INPUT',
    port      => $syslog_port,
    proto     => 'tcp',
  })

  # Admin Firewall Rules (currently only accepting hard coded rules)
  ensure_resource(profile::firewall::fwrule, any2array($admin_ips), {
    direction => 'INPUT',
    port      => $web_port,
    proto     => 'tcp',
  })



}

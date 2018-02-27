#
# === Class: profile::elasticsearch_local
#
# Setup simple ElasticSearch
#
# === Parameters
#
# - cluster_name - elasticsearch cluster name (string) - default: 'elastic_search'
# - use_swap_file - Create a swap file for systems that are low on memory
#      default: false
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::elasticsearch_local':
#           cluster_name  => 'MySpecialCluster',
#   }
#
# [*Hiera YAML*]
#   profile::elasticsearch_local::cluster_name: MySpecialCluster
#
class profile::elasticsearch_local (
  $cluster_name = 'elastic_search',
  $use_swap_file = false,
  $config = {}
) {

  validate_string($cluster_name)
  validate_bool($use_swap_file)

  # Java is needed for ES
  include ::java
  include ::repos::elastic

  # SWAP! (elasticsearch doesn't behave well without swap?)
  if $use_swap_file {
    include ::swap_file
  }

  # ElasticSearch
  # Some defaults, simple one host, all in one install
  $es_instance = "${cluster_name}-es"
  $default_config_hash = {
      'cluster.name'                         => $cluster_name,
      'discovery.zen.ping.multicast.enabled' => false,
      'discovery.zen.ping.unicast.hosts'     => ['localhost'],
      'network.host'                         => '127.0.0.1',
  }

  $merged_config_hash = deep_merge($default_config_hash, $config)

  $init_defaults = {
    'MAX_OPEN_FILES' => '65536',
  }
  include ::elasticsearch
  elasticsearch::instance { $es_instance:
    config        => $merged_config_hash,
    init_defaults => $init_defaults,
  }

}

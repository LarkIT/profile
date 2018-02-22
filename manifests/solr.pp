#
# === Class: profile::solr
#
# Setup Database - INHERIT CLASS
#  ### THIS CLASS DOESN'T DO ANYTHING
#  ### It just holds variables and settings
#  ### try solr::client or solr::server instead
#
#
# === Parameters
#
# [*port*]
#   Solr (Jetty) Port override
#   (int) Default '8983'
#
# === Sample invocation
#
# [*Puppet*]
#   # DON'T DO THIS! USE HIERA
#   class { 'profile::solr':
#     $port    => 9999,
#   }
#
# [*Hiera YAML*]
#   profile::solr::port: 9999
#
class profile::solr (
  $port  = 8983,
) {

  # Validate
  if is_integer($port) and ($port >= 1024) and ($port <= 65535) {
    #notice("DEBUG: solr port: ${port}")
  } else {
    fail('ERROR: profile::solr::db_port should be a number between 1024 and 65535')
  }

}

#
# === Class: profile::sftp
#
# Setup Database - INHERIT CLASS
#  ### THIS CLASS DOESN'T DO ANYTHING
#  ### It just holds variables and settings
#  ### try sftp::client or sftp::server instead
#
#
# === Parameters
#
# [*port*]
#   SFTP server port
#   (int) Default '22'
#
# === Sample invocation
#
# [*Puppet*]
#   # DON'T DO THIS! USE HIERA
#   class { 'profile::sftp':
#     $port    => 9999,
#   }
#
# [*Hiera YAML*]
#   profile::sftp::port: 9999
#
class profile::sftp (
  $port  = 22,
) {

  # Validate
  if is_integer($port) and ($port >= 1) and ($port <= 65535) {
    #notice("DEBUG: sftp port: ${port}")
  } else {
    fail('ERROR: profile::sftp::db_port should be a number between 1 and 65535')
  }

}

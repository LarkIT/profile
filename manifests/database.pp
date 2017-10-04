#
# === Class: profile::database
#
# Setup Database - INHERIT CLASS
#  ### THIS CLASS DOESN'T DO ANYTHING
#  ### It just holds variables and settings
#  ### try database::client or database::server instead
#
#
# === Parameters
#
# [*type*]
#   Type of database to install.
#   (String) Defaults to 'mysql'
#     Acceptable Values:
#       * mysql
#       * postgresql
#
# [*databases*]
#   Database Hash to create databases (passed to mysql::server::database)
#   (Hash) Defaults to {}
#
# [*db_port*]
#   Database Port override (will select a proper default based on $type)
#   (String) Default undef
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::database':
#     $type    => 'mysql',
#   }
#
# [*Hiera YAML*]
#   profile::database::type: mysql
#
class profile::database (
  $type      = 'mysql',
  $databases = {},
  $db_port   = undef,
) {

  # Validate
  validate_string($type)

  # I tried to put this in params.pp, but it wasn't playing nicely
  if $db_port {
    if is_integer($db_port) and ($db_port >= 1024) and ($db_port <= 65535) {
      $port = $db_port
    } else {
      fail('ERROR: profile::database::db_port should be a number between 1024 and 65535')
    }
  } else {
    case $type {
      'mysql': {
        $port = 3306
      }
      'postgresql': {
        $port = 5432
      }
      default: {
        fail('Unacceptable value at profile::database::type')
      }
    }
  }
}

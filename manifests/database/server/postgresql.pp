# Class: profile::database::server::postgresql
# Purpose: Install PostgreSQL server and setup databases / roles based on parameters
#
# Parameters:
# - databases - HASH of database_Name: { database parameters hash }
#       -- See README.md or puppetlabs/postgresql docs for details
# - roles - HASH to be pased to postgresql::server::role
# - database_grants - HASH to be passed to postgresql::server::database_grant
# - table_grants - HASH to be passed to postgresql::server::database_grant
# - grants - HASH to be passed to postgresql::server::grant
# - create_db_roles - LIST (array) of users to add the "createdb" role to
#            (OR)   - HASH of users with hashes of their role arguments
# - hba_rules - HASH of HBA Rules (see puppetlabs-postgresql docs)
# - extensions - HASH of extensions and arguments to pass to postgresql::server::extension
#
# NOTE: See puppetlabs/postgresql docs for server/global parameters
#
class profile::database::server::postgresql (
  $databases               = $profile::database::databases,
  $roles                   = {},
  $database_grants         = {},
  $table_grants            = {},
  $grants                  = {},
  $create_db_roles         = {},
  $hba_rules               = {},
  $extensions              = {},
) inherits profile::database {

  validate_hash($databases)
  validate_hash($roles)
  validate_hash($database_grants)
  validate_hash($table_grants)
  validate_hash($create_db_roles)
  validate_hash($hba_rules)
  # Unfortunately, because $create_db_roles can be either an array OR a hash, we
  # can't validate it.

  # Set some global parameters
  include ::postgresql::globals

  # Install Postgresql Server - note that we're not using built-in firewalling,
  # because we want to use host-specific firewall rules.

  include ::postgresql::server
  include ::postgresql::server::contrib

  postgresql::server::config_entry { 'track_counts':
    value   => 'on',
    require => Class['postgresql::server'],
    before  => Anchor['profile::database::server::postgresql::begin1'],
  }

  if str2bool($::settings::storeconfigs) {
    Postgresql::Server::Pg_hba_rule <<| tag == "ptag_hba_${::environment}_${::app_name}_${::client}_${::app_tier}_in_app_to_db" |>>
  }

  # Manual HBA Rules
  create_resources('postgresql::server::pg_hba_rule', $hba_rules)

  anchor { 'profile::database::server::postgresql::begin1':
    before => Anchor['profile::database::server::postgresql::end1'],
  }

  # Ensure that $create_db_roles have the createdb privilege
  # - this accepts a string, list or hash
  if is_hash($create_db_roles) {
    create_resources('postgresql::server::role', $create_db_roles, {
      createdb => true,
      require  => [ Class['postgresql::server'], Anchor['profile::database::server::postgresql::begin1'], ],
      before  => Anchor['profile::database::server::postgresql::end1'],
    })
  } else {
    ensure_resource('postgresql::server::role', $create_db_roles, {
      createdb => true,
      require  => [ Class['postgresql::server'], Anchor['profile::database::server::postgresql::begin1'], ],
      before  => Anchor['profile::database::server::postgresql::end1'],
    })
  }

  anchor { 'profile::database::server::postgresql::end1':
    require => Anchor['profile::database::server::postgresql::begin1'],
  }

  # Create the databases specified by the hash $databases
  create_resources('postgresql::server::database', $databases, {
    require => [ Class['postgresql::server'], Anchor['profile::database::server::postgresql::end1'], ],
  })

  # Ensure that $extensions are created
  if is_hash($extensions) {
    create_resources('postgresql::server::extension', $extensions)
  } else {
    fail('extensions must be a hash! see puppetlabs-postgresql docs for details')
  }

  # Create roles specified by the hash $roles
  create_resources('postgresql::server::role', $roles, {
    require => [ Class['postgresql::server'], Anchor['profile::database::server::postgresql::end1'], ],
  })

  # Create the database_grants specified by the hash $database_grants
  create_resources('postgresql::server::database_grant', $database_grants, {
    require => [ Class['postgresql::server'], Anchor['profile::database::server::postgresql::end1'], ],
  })

  # Create the table_grants specified by the hash $table_grants
  create_resources('postgresql::server::table_grant', $table_grants, {
    require => [ Class['postgresql::server'], Anchor['profile::database::server::postgresql::end1'], ],
  })

  # Create the grants specified by the hash $grants
  create_resources('postgresql::server::grant', $grants, {
    require => [ Class['postgresql::server'], Anchor['profile::database::server::postgresql::end1'], ],
  })

}

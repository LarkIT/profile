#
# === Class: profile::database::client::mysql
#
# Setup / Install MySQL Client software
#
# === Parameters
#
# NONE: for paramters see puppetlabs/mysql class
#
# === Sample invocation
#
# [*Puppet*]
#   include profile::database::client::mysql
#
# [*Hiera YAML*]
#   #N/A

class profile::database::client::mysql () {

  include ::mysql::client
  include ::mysql::bindings

}

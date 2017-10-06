#
# === Class: profile::shibboleth
#
# Setup Shibboleth
#
# === Parameters
#
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::shibboleth': }
#
#
class profile::shibboleth (
  $sso = {},
  $metadata = {},
  $attribute_map = {},
  $generate_cert = true,
) {
  #Include repo
#  include ::repos::shibboleth

#  ensure_packages('wget')

  # Set up Apache Module
#  include ::apache::mod::shib

  # Initialise Shibboleth configuration and services
#  include ::shibboleth

  # Set up the Shibboleth Single Sign On (sso) module
#  create_resources('::shibboleth::sso', $sso)
#  create_resources('::shibboleth::metadata', $metadata)
#  create_resources('::shibboleth::attribute_map', $attribute_map)

#  if $generate_cert {
#    include shibboleth::backend_cert
#  }

#  file{ '/etc/shibboleth/attribute-map.xml':
#    ensure => file,
#    owner  => 'shibd',
#    group  => 'shibd',
#    mode   => '0644',
#    source => "puppet:///modules/${module_name}/attribute-map.xml",
#    notify => Service[ 'shibd' ],
#  }
}

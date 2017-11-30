# Foreman Profile
class profile::foreman (
  $git_webhook_config = {},
) {

  firewall { '100 INPUT allow http(s) from all':
    dport  => [ '8080', '443', '8140', '8088' ],
    proto  => 'tcp',
    action => 'accept',
    chain  => 'INPUT',
  }

  include r10k
  include r10k::webhook::config
  include puppetdb

  # From KAFO (forman installer) -
  #  (/usr/share/gems/gems/kafo-2.0.0/modules/kafo_configure/manifests/init.pp)
  #hiera_include('classes')
  include foreman
  include foreman_proxy
  include puppet
  include foreman::cli
  include foreman::plugin::default_hostgroup
  include foreman::plugin::setup
  include foreman::compute::ec2

  #class{ 'puppet':
  #  server_additional_settings => true,
  #}

  class {'::r10k::webhook':
    require => Class['r10k::webhook::config'],
  }

  $git_webhook_config_defaults = {
    ensure => present,
  }

  if $git_webhook_config != {} {
    $git_webhook_config.each |$index, $value| {
      $git_webhook_config_merged = deep_merge($git_webhook_config_defaults,$value)
      git_webhook{ $index:
        * => $git_webhook_config_merged
      }
    }
  }

  $pkcs_private_key = 'pkcs7_private_key: /etc/puppetlabs/puppet/keys/private_key.pkcs7.pem'
  $pkcs_public_key  = 'pkcs7_public_key: /etc/puppetlabs/puppet/keys/public_key.pkcs7.pem'
  $config_yaml = "---\n${pkcs_private_key}\n${pkcs_public_key}"

  package { 'cli-hiera-eyaml':
    ensure   => present,
    name     => 'hiera-eyaml',
    provider => gem,
  }

  file{ '/etc/eyaml':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  }

  file{ '/etc/eyaml/config.yaml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $config_yaml,
    require => File[ '/etc/eyaml' ],
  }

  class { 'hiera':
    manage_package     => true,
    puppet_conf_manage => false,
    datadir_manage     => false,
    eyaml              => true,
    eyaml_extension    => 'yaml',
    provider           => 'puppetserver_gem',
    master_service     => 'puppetserver',
    hierarchy          => [
      'nodes/%{::trusted.certname}',
      '%{::trusted.extensions.pp_application}/%{::trusted.extensions.pp_environment}/%{::trusted.extensions.pp_role}',
      '%{::trusted.extensions.pp_application}/%{::trusted.extensions.pp_role}',
      '%{::trusted.extensions.pp_application}/%{::trusted.extensions.pp_environment}',
      '%{::trusted.extensions.pp_application}/common',
      '%{::trusted.extensions.pp_environment}/%{::trusted.extensions.pp_role}',
      'role/%{::trusted.extensions.pp_role}',
      'role/%{::role}',
      '%{::trusted.extensions.pp_role}',
      '%{::trusted.extensions.pp_environment}',
      'common',
     ],
#    hierarchy          => [
#      'nodes/%{::trusted.certname}',
#      '%{::trusted.extensions.pp_environment}/%{::trusted.extensions.pp_role}',
#      'role/%{::trusted.extensions.pp_role}',
#      'role/%{::role}',
#      'common',
#    ],
  }

  file{ "/etc/pki/tls/certs/${fqdn}.pem":
    mode    => '0644',
    source  => "/etc/puppetlabs/puppet/ssl/certs/${fqdn}.pem",
  }

  file{ "/etc/pki/tls/certs/ca.pem":
    mode    => '0644',
    source  => "/etc/puppetlabs/puppet/ssl/certs/ca.pem",
  }
  
  file{ "/etc/pki/tls/crl.pem":
    mode    => '0600',
    source  => "/etc/puppetlabs/puppet/ssl/crl.pem",
  }

  file{ "/etc/pki/tls/private/${fqdn}.pem":
    mode    => '0600',
    source  => "/etc/puppetlabs/puppet/ssl/private_key/${fqdn}.pem",
  }

}

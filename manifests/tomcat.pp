#
# Class name: profile::tomcat
# Purpose: Setup a SIMPLE Apache Tomcat app server
#
class profile::tomcat (
  $install_from_source = false,
  $wars = {},

) {
  validate_bool($install_from_source)
  validate_hash($wars)

  include ::java

  # Package from EPEL, which is in all our builds
  class { '::tomcat':
    install_from_source => $install_from_source,
  }

  tomcat::instance{ 'default':
      package_name => 'tomcat',
  }

  tomcat::service { 'default':
    use_jsvc     => false,
    use_init     => true,
    service_name => 'tomcat',
    require      => Tomcat::Instance['default'],
  }

  create_resources('::tomcat::war', $wars)

  # And a firewall...
  firewall { '100 INPUT allow http(s) from anyone':
    dport  => [ 80, 443, 8080 ],
    proto  => 'tcp',
    action => 'accept',
    chain  => 'INPUT',
  }

  firewall { '100 INPUT allow http(s) from anyone IPv6':
    dport    => [ 80, 443, 8080 ],
    proto    => 'tcp',
    action   => 'accept',
    chain    => 'INPUT',
    provider => 'ip6tables',
  }

}

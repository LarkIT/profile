#
# === Class: profile::pulp_server
#
# Setup Lark/CK IPA Server
#
# === Parameters
#
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::pulp_server': }
#
#
class profile::pulp_server (
){

  include ::repos::pulp2
  include ::apache
  include ::apache::mod::proxy
  include ::profile::letsencrypt
  class { 'pulp': }
  class { 'pulp::admin': }

  # Katello - this is how you want to do this?
  # This requires user input, build effective notice.  fact?
  # exec { '/usr/bin/pulp-qpid-ssl-cfg':
  #   require => Class['pulp::install'],
  #   notify  => Class['qpid::service'],
  # }

# to each consumer
# cd ``/etc/pki/pulp/qpid``
# scp ca.crt root@<host>:/etc/pki/pulp/qpid
# scp client.crt root@<host>:/etc/pki/pulp/qpid

  # file { '/etc/qpid/.pwgenerated':
  #   ensure => 'absent',
  #   notify => [Class['httpd::service'], Class['pulp::service'], Class['qpid::service'] ]
  # }

  firewall { '100 INPUT allow http(s) from all':
    dport  => [ '80', '443' ],
    proto  => 'tcp',
    action => 'accept',
    chain  => 'INPUT',
    before => Class['profile::letsencrypt'],
  }

  firewall { '100 INPUT allow http(s) from all IPv6':
    dport    => [ '80', '443' ],
    proto    => 'tcp',
    action   => 'accept',
    chain    => 'INPUT',
    before   => Class['profile::letsencrypt'],
    provider => 'ip6tables',
  }

  # firewall { '200 OUTPUT allow pulp/qpid ports from all':
  #   dport  => '5672',
  #   proto  => 'tcp',
  #   action => 'accept',
  #   chain  => 'INPUT',
  # }


  # need:
  # http://vault.centos.org/7.1.1503/extras/x86_64/Packages/python-blinker-1.3-2.el7.noarch.rpm
  # pulp repo
  #  chcon -t httpd_sys_rw_content_t /var/lib/pulp/
  # backup /etc/pki

}

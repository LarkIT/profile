#
# === Class: profile::ipa_server
#
# Setup Lark/CK IPA Server
#
# === Parameters
#
#
# === Sample invocation
#
# [*Puppet*]
#   class { 'profile::ipa_server': }
#
#
class profile::ipa_server (
  $base_dn   = 'dc=auth,dc=lark-it,dc=com',
  $recursion = 'localhost',
){

  include ::swap_file

  # Convert base_dn into string used by socket
  # dc=example,dc=com is transformed into EXAMPLE-COM
  $ldap_socket = inline_template("<%= @base_dn.split(',').map { |e| e.split('=')[1].upcase }.join('-') %>")

  package { ['ipa-server', 'bind', 'ipa-server-dns']:
    ensure => 'installed',
  }

  file { '/etc/named.conf':
    owner   => 'named',
    group   => 'root',
    mode    => '0440',
    content => template("${module_name}/ipa_server/named.conf.erb"),
    require => Package['bind'],
    notify  => Service['ipa'],
  }

  service { 'ipa':
    ensure => 'running',
    enable => true,
  }

  firewall { '500 IPA inbound TCP connections':
    action => 'accept',
    state  => 'NEW',
    chain  => 'INPUT',
    proto  => 'tcp',
    dport  => [ '53', '80', '88', '389', '443', '464', '636'],
  }

  firewall { '500 IPA inbound TCP connections IPv6':
    action   => 'accept',
    state    => 'NEW',
    chain    => 'INPUT',
    proto    => 'tcp',
    dport    => [ '53', '80', '88', '389', '443', '464', '636'],
    provider => 'ip6tables',
  }

  firewall { '500 IPA inbound UDP connections':
    action => 'accept',
    state  => 'NEW',
    chain  => 'INPUT',
    proto  => 'udp',
    dport  => [ '53', '88', '123', '464'],
  }

  firewall { '500 IPA inbound UDP connections IPv6':
    action   => 'accept',
    state    => 'NEW',
    chain    => 'INPUT',
    proto    => 'udp',
    dport    => [ '53', '88', '123', '464'],
    provider => 'ip6tables',
  }

  Firewall <<| tag == 'ipa_server_replication' |>>

  if $ec2_metadata {
    $_my_ip = ${facts[ec2_metadata][public-ipv4]}
  } else {
    $_my_ip = $::ipaddress
  }

  # Outbound rules for othe clients to connect to IPA server
  firewall { '200 OUTPUT allow IPA TCP ports':
    dport       => [ '88', '389', '464', '636'],
    proto       => 'tcp',
    action      => 'accept',
    chain       => 'OUTPUT',
    destination => '0.0.0.0/0',
  }

  firewall { '200 OUTPUT allow IPA TCP ports IPv6':
    dport       => [ '88', '389', '464', '636'],
    proto       => 'tcp',
    action      => 'accept',
    chain       => 'OUTPUT',
    destination => '0.0.0.0/0',
    provider    => 'ip6tables',
  }

  firewall { '200 OUTPUT allow IPA UDP ports':
    dport       => [ '88', '464'],
    proto       => 'udp',
    action      => 'accept',
    chain       => 'OUTPUT',
    destination => '0.0.0.0/0',
  }

  firewall { '200 OUTPUT allow IPA UDP ports IPv6':
    dport       => [ '88', '464'],
    proto       => 'udp',
    action      => 'accept',
    chain       => 'OUTPUT',
    destination => '0.0.0.0/0',
    provider    => 'ip6tables',
  }

  # Input and output rules used between servers for replication
  @@firewall { "500 INPUT allow IPA replication TCP ports from ${::hostname}":
    dport  => [ '9443', '9444', '9445', '7389' ],
    proto  => 'tcp',
    action => 'accept',
    chain  => 'INPUT',
    source => $_my_ip,
    tag    => 'ipa_server_replication',
  }

  Firewall <<| tag == 'ipa_server_replication' |>>

  firewall { '200 OUTPUT allow IPA replication TCP ports':
    dport       => [ '9443', '9444', '9445', '7389' ],
    proto       => 'tcp',
    action      => 'accept',
    chain       => 'OUTPUT',
    destination => '0.0.0.0/0',
  }

  firewall { '200 OUTPUT allow IPA replication TCP ports IPv6':
    dport       => [ '9443', '9444', '9445', '7389' ],
    proto       => 'tcp',
    action      => 'accept',
    chain       => 'OUTPUT',
    destination => '0.0.0.0/0',
    provider    => 'ip6tables',
  }
}

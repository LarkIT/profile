define profile::openvpn::users (
  String $username = $title,
  String $salt,  
) {
  user { "${username}":
     ensure => present,
     comment => "Managed by Puppet - OpenVPN role",
     shell => "/bin/bash",
  }
}


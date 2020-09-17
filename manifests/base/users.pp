# Class: profile::base::users
#
# Purpose: Ensure the root user's password is configured correctly and create an emergency user if requested.
#
#
class profile::base::users (
  $root_pw         = $::root_pw,
  $emergency_pw    = undef,
  $emergency_key   = undef,
  $centos_user     = false,
  $centos_user_key = undef,
){

  if $root_pw {
    user { 'root':
      home           => '/root',
      comment        => "root@${::fqdn}",
      password       => $root_pw,
      purge_ssh_keys => true,
    }
  }

  if $emergency_pw {
    group { 'emergency':
      ensure => 'present',
      system => true,
    }

    user { 'emergency':
      comment        => 'Emergency User',
      home           => '/var/lib/.emergency',
      password       => $emergency_pw,
      gid            => 'emergency',
      groups         => [ 'wheel' ],
      purge_ssh_keys => true,
      system         => true,
      managehome     => true,
      require        => Group['emergency'],
    }

    ssh_authorized_key { 'emergency':
      type => 'ssh-rsa',
      name => 'emergency SSH Key',
      user => 'emergency',
      key  => $emergency_key,
    }

    sudo::conf { 'emergency':
      content  => 'emergency ALL=(ALL) ALL',
    }
  }

  if $centos_user {
    group { 'centos':
      ensure => present,
    }
    user { 'centos':
      gid            => 'centos',
      groups         => [ 'wheel' ],
      purge_ssh_keys => true,
      system         => true,
      managehome     => true,
      require        => Group['centos']
    }
    ssh_authorized_key { 'emergency':
      type => 'ssh-rsa',
      name => 'centos_user_key',
      user => 'centos',
      key  => $centos_user_key,
    }
    
  }
  else {
    user { 'centos': ensure => absent }
  }
}

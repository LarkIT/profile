# Class: profile::base::users
#
# Purpose: Ensure the root user's password is configured correctly and create an emergency user if requested.
#
#
class profile::base::users (
  $root_pw       = $::root_pw,
  $emergency_pw  = undef,
  $emergency_key = undef,
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

}

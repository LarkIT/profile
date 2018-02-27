#
# Class: profile::sshkeys
# Purpose: Manage SSH Authorized Keys
#
# Example:
#  # Manage SSH Keys
#  ensure_resource(profile::sshkeys, $username, {
#    keys => concat($lark::global_ssh_keys, $additional_ssh_keys),
#    user_home_dir   => $_user_home_dir,
#  })
#
define profile::sshkeys (
  $user          = $name,
  $keys          = undef,
) {

  validate_string($user)
  validate_hash($keys)

  # We are prefixing the "user" to provide  uniqueness due to puppetisims
  $_user_keys = prefix($keys, "${user}-")
  create_resources( 'ssh_authorized_key', $_user_keys, {
    ensure  => present,
    'type'  => 'ssh-rsa',
    user    => $user,
  })

  #   ssh_authorized_key { "${user}@${::fqdn}-${name}":
  #     ensure  => present,
  #     key     => $name,
  #     user    => $user,
  #     type    => rsa,
  #     require => File[$ssh_authorized_keys]
  #   }
}

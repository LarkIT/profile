#
# Class name: profile::duplicity.pp
# Purpose: Setup Duplicity
#
class profile::duplicity (
  $profiles = {},
  $public_keys = {},
  $private_keys = {},
  $files = {},
) {
  validate_hash($profiles)
  validate_hash($public_keys)
  validate_hash($private_keys)
  validate_hash($files)

  # Base Class -- note set any settings in hiera
  include ::duplicity

  create_resources( '::duplicity::profile', $profiles)
  create_resources( '::duplicity::public_key', $public_keys)
  create_resources( '::duplicity::private_key', $private_keys)
  create_resources( '::duplicity::file', $files)

}

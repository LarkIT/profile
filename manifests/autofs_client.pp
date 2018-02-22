#
# Class name: profile::autofs_client.pp
# Purpose: Setup AutoFS Client
#
# === Parameters
#
# [*additional_packages*]
#   A list of additional packages to install on the host.
#   (Array) Defaults to [].
#
class profile::autofs_client (
  $additional_packages = [],
) {
  validate_array($additional_packages)
  ensure_packages($additional_packages)
  # See: https://forge.puppetlabs.com/EagleDelta2/autofs
  include ::autofs
}

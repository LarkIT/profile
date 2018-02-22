#
# Class name: profile::datadisks.pp
# Purpose: Setup Additional Data Disks
#
# === Parameters
#
# [*additional_packages*]
#   A list of additional packages to install on the host.
#   (Array) Defaults to [].
#
class profile::datadisks (
  $additional_packages = [],
) {
  validate_array($additional_packages)
  ensure_packages($additional_packages)

  # crude check to see if there is a second disk
  if is_integer($::blockdevice_sdb_size) {
    # See: https://forge.puppetlabs.com/puppetlabs/lvm
    include ::lvm
  } else {
    notice("NO DATA DISK DETECTED! (${::blockdevices}) --  Using System Disk")
  }
}

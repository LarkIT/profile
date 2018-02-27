# Class: profile::base::files
#
# Purpose: Install arbitrary files (such as SSL certificates) onto hosts
#
#
class profile::base::files (
  $files = hiera_hash('profile::base::files::files', {}),
) {

  create_resources('file', $files)

}

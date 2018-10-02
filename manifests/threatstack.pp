#
# === Class: profile::threatstack
#
# Setup threatstack agent
#
# === Parameters
#

class profile::threatstack (
  $threatstack_enable = false,
)
{
    if ($threatstack_enable) {
        include threatstack
    }

}

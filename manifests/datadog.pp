#
# === Class: profile::datadog
#
# Setup datadog agent
#
# === Parameters
#

class profile::datadog (
  $datadog_enable = false,
)
{
    if ($datadog_enable) {
        include datadog_agent
    }

}

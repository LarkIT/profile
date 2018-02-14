#
# === Class: profile::datadog
#
# Setup datadog agent
#
# === Parameters
#

class profile::datadog
{
    include datadog_agent
}

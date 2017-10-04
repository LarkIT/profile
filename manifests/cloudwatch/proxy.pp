# Necessary since the Puppet Cloudwatch module we use
# predates post-setup proxy support

class profile::cloudwatch::proxy (
    $conf_file = "/var/awslogs/etc/proxy.conf",
    $http_proxy = undef,
    $https_proxy = undef,
    $no_proxy_list = []
) {
    $no_proxy_string = join($no_proxy_list, ",")
    $proxyfile_contents = 
    "HTTP_PROXY=${http_proxy}\nHTTPS_PROXY=${https_proxy}\nNO_PROXY=${no_proxy_string}\n"

    file { "${conf_file}":
        ensure  => 'file',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => "${proxyfile_contents}",

    }
    
}
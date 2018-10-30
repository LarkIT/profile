# === Class: profile::monitoring::sensu_server
#
# Setup Monitoring Server (sensu)
#
# === Parameters
#
#
class profile::monitoring::sensu_server (
  $rabbitmq_srv_cacert = undef,
  $rabbitmq_srv_cert   = undef,
  $rabbitmq_srv_key    = undef,
  $rabbitmq_password   = $::sensu::rabbitmq_password,
  $admin_ips           = $::profile::firewall::admin_ips,
  $handlers            = {},
  $handler_packages    = [],
  $http_cert_provider  = 'letsencrypt'
){

  if ! member(['letsencrypt', 'ipa'], $http_cert_provider) {
    fail("profile::monitoring::sensu_server: Valid values for ${http_cert_provider} are letsencrypt and ipa")
  }

  include ::profile::firewall
  include ::repos::sensu
  include ::repos::epel
  include ::firewall
  include ::uchiwa
  include ::sensu
  include ::apache
  include ::selinux

  # Redis setup
  class { '::redis': }
  ensure_packages('rubygem-redis')

  # Rabbitmq setup
  class { '::rabbitmq':
    package_provider  => 'yum',
    admin_enable      => true,
    delete_guest_user => true,
    repos_ensure      => false,
    ssl               => true,
    ssl_only          => true,
    ssl_cacert        => '/etc/rabbitmq/ssl/server_cacert.pem',
    ssl_cert          => '/etc/rabbitmq/ssl/server_cert.pem',
    ssl_key           => '/etc/rabbitmq/ssl/server_key.pem',
  }

  file { '/etc/rabbitmq/ssl/server_cacert.pem':
    owner   => 'rabbitmq',
    group   => 'rabbitmq',
    mode    => '0440',
    content => $rabbitmq_srv_cacert,
    require => Class['rabbitmq::install'],
    notify  => Class['rabbitmq::service'],
  }

  file { '/etc/rabbitmq/ssl/server_cert.pem':
    owner   => 'rabbitmq',
    group   => 'rabbitmq',
    mode    => '0440',
    content => $rabbitmq_srv_cert,
    require => Class['rabbitmq::install'],
    notify  => Class['rabbitmq::service'],
  }

  file { '/etc/rabbitmq/ssl/server_key.pem':
    owner   => 'rabbitmq',
    group   => 'rabbitmq',
    mode    => '0440',
    content => $rabbitmq_srv_key,
    require => Class['rabbitmq::install'],
    notify  => Class['rabbitmq::service'],
  }

  rabbitmq_vhost { 'sensu':
    ensure   => present,
  }

  rabbitmq_user { 'sensu':
    admin    => false,
    password => $rabbitmq_password,
  }

  rabbitmq_user_permissions { 'sensu@sensu':
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
  }

  # exec { 'rabbitmq_ssl':
  #   command => 'ipa-getcert request -f /etc/pki/tls/certs/rabbitmq.pem -k /etc/pki/tls/private/rabbitmq.key  -K rabbitmq/sensu.lark-it.com -N CN=sensu.lark-it.com,O=IPA.LARK-IT.COM -g 4096',
  #   onlyif  => 'test ! -f /etc/pki/tls/private/rabbitmq.key',
  #   path    => '/bin'
  # }

  # Needed for rabbitmq to bind to TCP socket
  if !defined(Selboolean['nis_enabled']) {
    selboolean { 'nis_enabled':
      persistent => true,
      value      => on,
      before     => Class['Rabbitmq::Service'],
    }
  }

  firewall { '500 rabbitmq inbound connections':
    action => 'accept',
    state  => 'NEW',
    chain  => 'INPUT',
    dport  => [5671],
  }

  # NOTE: This this rule requires sensu be run in AWS.  Will need to have some logic to run elsewhere
  @@firewall { "200 OUTPUT allow sensu/rabbitmq ports tcp at ${::ec2_public_ipv4}:5671":
    dport       => '5671',
    proto       => 'tcp',
    action      => 'accept',
    chain       => 'OUTPUT',
    destination => $::ec2_public_ipv4,
    tag         => 'ptag_sensu_server',
  }

  #create_resources(sensu::handler, $handlers)
  ensure_packages($handler_packages)

  # vhost for uchiwa

  exec { 'ipa-getkeytab':
    command => "/bin/echo Get keytab \
      && KRB5CCNAME=KEYRING:session:get-http-service-keytab kinit -k \
      && KRB5CCNAME=KEYRING:session:get-http-service-keytab /usr/sbin/ipa-getkeytab -s ${::default_ipa_server} -k /etc/httpd/conf/http.keytab -p HTTP/sensu.lark-it.com \
      && kdestroy -c KEYRING:session:get-http-service-keytab",
    creates => '/etc/httpd/conf/http.keytab',
  } ->

  file { '/etc/httpd/conf/http.keytab':
    ensure => file,
    owner  => apache,
    mode   => '0600',
  }

  ::apache::mod { 'authnz_pam': package => 'mod_authnz_pam' }
  include ::apache::mod::auth_kerb

  if $http_cert_provider == 'letsencrypt' {
    include ::profile::letsencrypt
    $_ssl_cert = "/etc/letsencrypt/live/${::fqdn}/fullchain.pem"
    $_ssl_key = "/etc/letsencrypt/live/${::fqdn}/privkey.pem"
    $_ssl_ca = undef
  } elsif $http_cert_provider == 'ipa' {
    exec { 'http_ssl':
      command => 'ipa-getcert request -f /etc/pki/tls/certs/sensu.http.pem -k /etc/pki/tls/private/sensu.http.key  -K HTTP/sensu.lark-it.com -N CN=sensu.lark-it.com,O=IPA.LARK-IT.COM -g 4096',
      onlyif  => 'test ! -f /etc/pki/tls/private/sensu.http.key',
      path    => '/bin',
    }
    $_ssl_cert = '/etc/pki/tls/certs/sensu.http.pem'
    $_ssl_key = '/etc/pki/tls/private/sensu.http.key'
    $_ssl_ca =  '/etc/ipa/ca.crt'
  }

  apache::vhost { 'uchiwa-http':
    docroot                => '/var/www/html',
    manage_docroot         => false,
    port                   => 443,
    servername             => $::fqdn,
    serveraliases          => 'sensu.lark-it.com',
    serveradmin            => 'admin@lark-it.com',
    auth_kerb              => true,
    krb_method_negotiate   => 'on',
    krb_auth_realms        => ['AUTH.LARK-IT.COM'],
    krb_local_user_mapping => 'on',
    krb_5keytab            => '/etc/httpd/conf/http.keytab',
    ssl                    => true,
    ssl_cert               => $_ssl_cert,
    ssl_key                => $_ssl_key,
    ssl_ca                 => $_ssl_ca,
    proxy_preserve_host    => true,
    proxy_pass             => [
      {
        path    => '/',
        url     => 'http://127.0.0.1:3000/',
        options => {
          'AuthName' => '"Kerberos Login"',
          'AuthType' => 'Kerberos',
          'Require'  => 'valid-user',
        },
      },
    ],
  }

  # Allow apache to authenticate through sssd to IPA
  if !defined(Selboolean['httpd_dbus_sssd']) {
    selboolean { 'httpd_dbus_sssd':
      persistent => true,
      value      => on,
    }
  }

  # Allow apache to proxy to uchiwa
  if !defined(Selboolean['httpd_can_network_connect']) {
    selboolean { 'httpd_can_network_connect':
      persistent => true,
      value      => on,
    }
  }

  # if (is_string($admin_ips) and $admin_ips != '') or (is_array($admin_ips) and !empty($admin_ips)) {
  #   $fw_admin_ips = suffix(any2array($admin_ips), '||admin-uchiwa')
  #   ensure_resource(profile::firewall::fwrule, $fw_admin_ips, {
  #     direction => 'INPUT',
  #     port      => 443,
  #     proto     => 'tcp',
  #   })
  # }
}

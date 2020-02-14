class profile::daemon_reload {

  exec { '/bin/systemctl daemon-reload':
    refreshonly => true,
  }

}
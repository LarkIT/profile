class profile::systemd::daemon_reload {

  exec { '/bin/systemctl daemon-reload':
    refreshonly => true,
  }

}
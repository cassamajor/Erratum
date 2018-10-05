firehol_dependencies:
  pkg.installed:
    - pkgs:
      - zlib-devel
      - libuuid-devel
      - libmnl-devel
      - gcc
      - make
      - git
      - autoconf
      - autogen
      - automake
      - pkgconfig
      - traceroute
      - ipset
      - curl
      - nodejs
      - zip
      - unzip
      - jq

install_firehol:
  cmd.script:
    - source: https://raw.githubusercontent.com/firehol/netdata-demo-site/master/install-all-firehol.sh
    - runas: root

  file.managed:
    - name: /etc/firehol/firehol.conf
    - source: salt://files/firehol.conf
    - template: jinja
    - backup: minion

/etc/rsyslog.d/log_firehol.conf:
  file.managed:
    - source: salt://files/log_firehol.conf
    - backup: minion

/etc/logrotate.d/logrotate_firehol.conf:
  file.managed:
    - source: salt://files/logrotate_firehol.conf
    - backup: minion

firehol start:
  cmd.run: []

echo 1 >/sys/kernel/mm/ksm/run:
  cmd.run: []

echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs:
  cmd.run: []

"sleep 60 && /usr/sbin/firehol start":
  cron.present:
    - identifier: "FIREHOL"
    - comment: "Upon reboot, wait 60 seconds then enable Firehol."
    - user: root
    - special: '@reboot'

/usr/src/netdata.git/netdata-updater.sh:
  cron.present:
      - identifier: "NETDATA"
      - comment: "Auto-update Netdata daily."
      - user: root
      - special: '@daily'
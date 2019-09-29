Download IPrange and Firehol packages:
  cmd.script:
    - source: salt://files/firehol+iprange.sh
    - runas: root

Install iprange:
  pkg.installed:
    - sources:
        - iprange: salt://files/iprange-latest.rpm

Install, configure, and enable Firehol:
  pkg.installed:
    - sources:
      - firehol: salt://files/firehol-latest.rpm
  file.managed:
    - name: /etc/firehol/firehol.conf
    - source: salt://files/firehol.conf
    - template: jinja
    - backup: minion
  service.running:
    - name: firehol
    - enabled: True
    - watch:
      - pkg: Install, configure, and enable Firehol

Allow rsyslog to manage Firehol logs:
  file.managed:
    - name: /etc/rsyslog.d/log_firehol.conf
    - source: salt://files/log_firehol.conf
    - template: jinja
    - backup: minion

Logrotate Firehol logs:
  file.managed:
    - name: /etc/logrotate.d/logrotate_firehol.conf
    - source: salt://files/logrotate_firehol.conf
    - template: jinja
    - backup: minion

Install Netdata:
  cmd.script:
    - source: https://my-netdata.io/kickstart.sh
    - args: "--dont-wait --stable-channel"
    - runas: root

Optimize Netdata Memory Usage:
  file.managed:
    - name: /etc/tmpfiles.d/enable-ksm.conf
    - contents: |
        #    Path                                 Mode UID  GID  Age Argument
        w    /sys/kernel/mm/ksm/run               -    -    -    -   1
        w    /sys/kernel/mm/ksm/sleep_millisecs   -    -    -    -   1000

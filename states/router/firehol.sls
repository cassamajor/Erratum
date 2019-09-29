Download IPrange and Firehol packages:
  cmd.script:
    - source: salt://files/firehol+iprange.sh
    - runas: root

Install IPrange and Firehol:
  pkg.installed:
    - sources:
        - iprange: salt://files/iprange.rpm
        - firehol: salt://files/firehol.rpm

Configure and enable Firehol:
  file.managed:
    - name: /etc/firehol/firehol.conf
    - source: salt://files/firehol.conf
    - template: jinja
    - backup: minion
  service.running:
    - name: firehol
    - enabled: True
    - watch:
      - pkg: Install IPrange and Firehol

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
  file.manage:
    - name: /etc/systemd/system/ksm.service
    - contents: |
        [Service]
        Type=oneshot
        RemainAfterExit=yes
        ExecStart=echo 1 >/sys/kernel/mm/ksm/run
        ExecStart=echo 1000 >/sys/kernel/mm/ksm/sleep_millisecs

        [Unit]
        WantedBy=netdata.service

        [Install]
        WantedBy=multi-user.target
  service.running:
    - name: ksm
    - enable: True
    - watch:
        file: Optimize Netdata Memory Usage
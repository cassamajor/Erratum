Setenforce to 0 to avoid whiptail dialog:
  cmd.run:
    - name: setenforce 0

SetupVars Configuration File:
  file.managed:
    - name: /etc/pihole/setupVars.conf
    - source: salt://files/setupVars.conf
    - template: jinja
    - backup: minion
    - makedirs: True

Adlists Configuration File:
  file.managed:
    - name: /etc/pihole/adlists.list
    - source: salt://files/adlists.list
    - backup: minion
    - makedirs: True

Github Issue 2161:
  cmd.run:
    - name: yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm; yum-config-manager --enable remi-php72

Install Pi-hole:
  cmd.script:
    - source: "https://raw.githubusercontent.com/pi-hole/pi-hole/master/automated%20install/basic-install.sh"
    - runas: root
    - args: "--unattended"

Github Issue 2391:
  cmd.run:
    - name: touch /etc/lighttpd/external.conf
    - onchanges_in:
        - service: lighttpd
  service.running:
    - name: lighttpd
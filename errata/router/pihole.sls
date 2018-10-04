setenforce 0:
  cmd.run: []

/etc/pihole/setupVars.conf:
  file:
    - managed
    - source: salt://files/setupVars.conf
    - template: jinja
    - backup: minion
    - makedirs: True

install_pihole:
  cmd.script:
    - source: "https://raw.githubusercontent.com/pi-hole/pi-hole/master/automated%20install/basic-install.sh"
    - runas: root
    - args: "--unattended"

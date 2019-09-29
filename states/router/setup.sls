{{ pillar['username'] }}:
  user.present: []
  ssh_auth.present:
    - user: {{ pillar['username'] }}
    - source: salt://files/authorized_keys
    - config: '%h/.ssh/authorized_keys'

/etc/sudoers:
  file.append:
    - text: "{{ pillar['username'] }} ALL=(ALL) NOPASSWD: ALL"

epel-release:
  pkg.installed: []

base_packages:
  pkg.installed:
    - pkgs:
      - vim-enhanced
      - git
      - bash-completion
      - wget
      - bind-utils
      - mtr
      - iptraf-ng
      - screen
      - rsync
    - require:
      - pkg: epel-release

/etc/vimrc:
  file.append:
    - source: salt://files/vimrc

yum-cron:
  pkg.installed: []
  service.running:
    - enable: True
    - watch:
      - file: /etc/yum/yum-cron.conf
  file.replace:
    - name: /etc/yum/yum-cron.conf
    - repl: apply_updates = yes
    - pattern: apply_updates = no

Define FQDN for router:
  cmd.run:
    - name: hostnamectl set-hostname {{ pillar['hostname'] }}.{{ pillar['domain'] }}

# This setting will remove an ISP's DNS servers pushed through DHCP
{% if pillar['internal_router'] == False %}
modify_wan_dns:
  cmd.run:
    - name: nmcli con mod {{ pillar['wan_interface'] }} ipv4.ignore-auto-dns yes ipv4.dns "{{ pillar['pihole_dns_1'] }} {{ pillar['pihole_dns_2'] }}"

apply_wan_dns:
  cmd.run:
    - name: nmcli device reapply {{ pillar['wan_interface'] }}
{% endif %}

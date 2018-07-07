{% set accounts = ['user1', 'user2'] %}
{% set is_router_internal = 'no' %}
{% set wan_interface = 'ens33' %}
{% set lan_interface = 'ens34' %}

{% for user in accounts %}
{{ user }}:
  user.present: []
  ssh_auth.present:
    - user: {{ user }}
    - source: salt://files/authorized_keys
    - config: '%h/.ssh/authorized_keys'

/etc/sudoers:
  file.append:
    - text: "{{ user }} ALL=(ALL) NOPASSWD: ALL"
{% endfor %}

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


# The below commands are to remove DNS settings on the WAN interface implemented by a DHCP server.
# If DNS settings on the WAN interface should be managed by a DHCP server, remove these commands.
# Possible use case is to remove an ISP's DNS servers pushed through DHCP.
{% if is_router_internal == 'no' %}
  modify_wan_dns:
    cmd.run:
      - name: nmcli con mod {{ wan_interface }} ipv4.ignore-auto-dns yes ipv4.dns "8.8.8.8 8.8.4.4"

  apply_wan_dns:
    cmd.run:
      - name: nmcli device reapply {{ wan_interface }}
{% endif %}

Download WireGuard repository and install WireGuard Packages:
  cmd.run:
    - name: curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
  pkg.installed:
    - pkgs:
      - wireguard-dkms
      - wireguard-tools

{% for dir_name in ['/etc/wireguard/', '/etc/wireguard/server_configs', '/etc/wireguard/server_keys', '/etc/wireguard/client_configs', '/etc/wireguard/client_keys'] %}
Create {{ dir_name }} directory:
  file.directory:
    - name: {{ dir_name }}
    - user: root
    - group: root
    - dir_mode: 710
    - file_mode: 700
    - makedirs: True
{% endfor %}

Install qrencode to generate QR codes:
  pkg.installed:
    - name: qrencode

Generate Private and Public Server Keys for {{ pillar['wireguard_interface'] }} in /etc/wireguard/:
  cmd.run:
    - name: wg genkey | tee {{ pillar['wireguard_interface'] }}_private.key | wg pubkey > {{ pillar['wireguard_interface'] }}_public.key
    - cwd: /etc/wireguard/

  {% for host in range(1,3) %}
Generate Private and Public Client Keys for wg{{ host }} in /etc/wireguard/client_configs/keys/:
  cmd.run:
    - name: wg genkey | tee wg{{ host }}_private.key | wg pubkey > wg{{ host }}_public.key
    - cwd: /etc/wireguard/client_configs/keys/
  {% endfor %}
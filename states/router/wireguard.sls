{% set wireguard_server_private_key = salt['cmd.run']('wg genkey') %}
{% set listen_port = salt['cmd.run']('shuf -i 49152-65535 -n 1') %}

# TODO: Make host addresses configurable based on pillar: This will require jinja regex + familiarity with nested dicts (look at user creation examples)
# TODO: Require packages state from setup.sls
# TODO: Fix Storing of Private Key

Allow Pihole to manage the WireGuard interface:
  file.managed:
    - name: /etc/dnsmasq.d/{{ pillar['wireguard_interface'] }}.conf
    - contents:
      - interface={{ pillar['wireguard_interface'] }}
    - template: jinja
  cmd.run:
    - name: pihole restartdns
    - onchanges:
      - file: Allow Pihole to manage the WireGuard interface


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

Store Server Private Keys for {{ pillar['wireguard_interface'] }} in /etc/wireguard/server_keys/:
  file.managed:
    - name: /etc/wireguard/server_keys/{{ pillar['wireguard_interface'] }}_private.key
    - contents:
      - {{ wireguard_server_private_key }}

Store Server Public Keys for {{ pillar['wireguard_interface'] }} in /etc/wireguard/server_keys/:
  cmd.run:
    - name: wg pubkey <<< {{ wireguard_server_private_key }} > {{ pillar['wireguard_interface'] }}_public.key
    - cwd: /etc/wireguard/server_keys/

Create {{ pillar['wireguard_interface'] }}.conf in /etc/wireguard/server_configs/:
  file.managed:
    - name: /etc/wireguard/server_configs/{{ pillar['wireguard_interface'] }}.conf
    - contents: |
        # Managed by Salt

        [Interface]
        Address = {{ pillar['internal_network'] }}
        PrivateKey = {{ wireguard_server_private_key }}
        ListenPort = {{ listen_port }}
    - template: jinja
    - backup: True

{% for host in range(2,4) %}
  {% set wireguard_client_private_key = salt['cmd.run']('wg genkey') %}

Create wg{{ host }}_private.key in /etc/wireguard/client_keys/:
  file.managed:
    - name: /etc/wireguard/client_keys/wg{{ host }}_private.key
    - contents: {{ wireguard_client_private_key }}
    - template: jinja

Create wg{{ host }}_public.key in /etc/wireguard/client_keys/:
  file.managed:
    - name: /etc/wireguard/client_keys//wg{{ host }}_public.key
    - contents: __slot__:salt:cmd.shell('wg pubkey <<< {{ wireguard_client_private_key }}')
    - template: jinja

Create wg{{ host }}_client.conf and qr_wg{{ host }}_client.conf in /etc/wireguard/client_configs/:
  file.managed:
    - name: /etc/wireguard/client_configs/wg{{ host }}_client.conf
    - contents: |
        # Managed by Salt

        [Interface]
        Address = 10.41.0.{{ host }}/24
        DNS = {{ pillar['dhcp_router'] }}
        PrivateKey = {{ wireguard_client_private_key }}

        [Peer]
        PublicKey = wireguard_server_public_key
        Endpoint = {{ pillar['public_ip'] }}:{{ listen_port }}
        AllowedIPs = 0.0.0.0/0
    - template: jinja
    - backup: True

Add WireGuard Server Public Key to wg{{ host }}_client.conf:
  file.replace:
    - name: /etc/wireguard/client_configs/wg{{ host }}_client.conf
    - pattern: wireguard_server_public_key
    - repl: __slot__:salt:cmd.shell('wg pubkey <<< {{ wireguard_server_private_key }}')
    - backup: False

Generate QR code configuration for wg{{ host }}_client.conf:
  cmd.run:
    - name: qrencode -t ansiutf8 < /etc/wireguard/client_configs/wg{{ host }}_client.conf > /etc/wireguard/client_configs/qr_wg{{ host }}_client.conf

Append wg{{ host }} [Peer] section to /etc/wireguard/server_configs/{{ pillar['wireguard_interface'] }}.conf:
  file.append:
    - name: /etc/wireguard/server_configs/{{ pillar['wireguard_interface'] }}.conf
    - text: |

        [Peer]
        PublicKey = wireguard_client_public_key
        AllowedIPs = 10.41.0.{{ host }}/32

Add wg{{ host }} WireGuard Client Public Key to /etc/wireguard/server_configs/{{ pillar['wireguard_interface'] }}.conf:
  file.replace:
  - name: /etc/wireguard/server_configs/{{ pillar['wireguard_interface'] }}.conf
  - pattern: wireguard_client_public_key
  - repl: __slot__:salt:cmd.shell('wg pubkey <<< {{ wireguard_client_private_key }}')
  - backup: False
{% endfor %}

Enable the {{ pillar['wireguard_interface'] }} interface on system boot:
  service.running:
    - name: wg-quick@{{ pillar['wireguard_interface']}}.service
    - enable: True
    - watch:
      - file: Create {{ pillar['wireguard_interface'] }}.conf in /etc/wireguard/server_configs/
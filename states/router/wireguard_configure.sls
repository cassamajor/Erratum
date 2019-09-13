{% set wireguard_server_private_key = salt['cmd.run']('wg genkey') %}
# {% set wireguard_server_public_key = salt['cmd.run']('cat /etc/wireguard/{{ pillar["wireguard_interface"] }}') %}
# TODO: For this to work, I would have to do a file.replace with __slot__:salt:cmd.shell for all public keys
# TODO: Try assigning Jinja to Jinja in Pillar

Allow Pihole to manage the WireGuard interface:
  file.managed:
    - name: /etc/dnsmasq.d/{{ pillar['wireguard_interface'] }}.conf
    - contents:
      - interface={{ pillar['wireguard_interface'] }}
    - template: jinja

Create {{ pillar['wireguard_interface'] }}.conf in /etc/wireguard/:
  file.managed:
    - name: /etc/wireguard/{{ pillar['wireguard_interface'] }}.conf
    - contents: |
        [Interface]
        Address = 10.41.0.1/24
        PrivateKey = {{ wireguard_server_private_key }}
        ListenPort = 51820
    - template: jinja

#Generate Private and Public Keys for {{ pillar['wireguard_interface'] }} in /etc/wireguard/keys/:
#  file.managed:
#    - name: /etc/wireguard/{{ pillar['wireguard_interface'] }}.conf
#    - contents: __slot__:salt:cmd.shell('wg pubkey <<< {{ wireguard_client_private_key }}')
#    - template: jinja

{% for host in range(1,3) %}
  {% set wireguard_client_private_key = salt['cmd.run']('wg genkey') %}

  Create wg{{ host }}_private.key in /etc/wireguard/client_configs/keys/:
    file.managed:
      - name: /etc/wireguard/client_configs/keys/wg{{ host }}_private.key
      - contents: {{ wireguard_client_private_key }}
      - template: jinja

  Create wg{{ host }}_public.key in /etc/wireguard/client_configs/keys/:
    file.managed:
      - name: /etc/wireguard/client_configs/keys//wg{{ host }}_public.key
      - contents: __slot__:salt:cmd.shell('wg pubkey <<< {{ wireguard_client_private_key }}')
      - template: jinja

  Create wg{{ host }}_client.conf and qr_wg{{ host }}_client.conf in /etc/wireguard/client_configs/:
    file.managed:
      - name: /etc/wireguard/client_configs/wg{{ host }}_client.conf
      - contents: |
          # Managed by Salt

          [Interface]
          Address = 10.41.0.{{ host }}/24
          DNS = 10.41.0.1
          PrivateKey = {{ wireguard_client_private_key }}

          [Peer]
          PublicKey = wireguard_server_public_key
          Endpoint = {{ pillar['public_ip'] }}:51820
          AllowedIPs = 0.0.0.0/0

  Add WireGuard Server Public Key to wg{{ host }}_client.conf:
    file.replace:
      - name: /etc/wireguard/client_configs/wg{{ host }}_client.conf
      - pattern: wireguard_server_public_key
      - repl: __slot__:salt:cmd.shell('wg pubkey <<< {{ wireguard_server_private_key }}')

  Generate QR code configuration for wg{{ host }}_client.conf:
    cmd.shell:
      - name: qrencode -t ansiutf8 < /etc/wireguard/client_configs/wg{{ host }}_client.conf > /etc/wireguard/client_configs/qr_wg{{ host }}_client.conf

  Append wg{{ host }} [Peer] section to /etc/wireguard/{{ pillar['wireguard_interface'] }}.conf:
    file.append:
      - name: /etc/wireguard/{{ pillar['wireguard_interface'] }}.conf
      - text: |

          [Peer]
          PublicKey = wireguard_client_public_key
          AllowedIPs = 10.41.0.{{ host }}/32

  Add wg{{ host }} WireGuard Client Public Key to /etc/wireguard/{{ pillar['wireguard_interface'] }}.conf:
    file.replace:
    - name: /etc/wireguard/{{ pillar['wireguard_interface'] }}.conf
    - pattern: wireguard_client_public_key
    - repl: __slot__:salt:cmd.shell('wg pubkey <<< {{ wireguard_client_private_key }}')
{% endfor %}

Enable the {{ pillar['wireguard_interface'] }} interface on system boot:
  service.running:
    - name: wg-quick@{{ pillar['wireguard_interface']}}.service
    - enable: True
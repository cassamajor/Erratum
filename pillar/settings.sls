{% set public_ip = salt['cmd.run']('curl -sL api.ipify.org') %}
{% set wan_ip = salt['cmd.shell']("ip route get 8.8.8.8 | awk '{print $7}'") %}


# OS Settings
username: 'router'
hostname: 'router'
domain: 'boxed'

# Firehol Settings
wan_interface: 'ens33'
lan_interface: 'ens34'
internal_network: '192.168.1.1/24'
{% if public_ip == wan_ip %}
internal_router: False
{% else %}
internal_router: True
{% endif %}
wan_ip: {{ wan_ip }}
public_ip: {{ public_ip }}
firehol_log_prefix: 'firehol: '
firehol_log_location: '/var/log/firehol.log'

# Pi-hole Settings:
dhcp_start: '192.168.1.50'
dhcp_end: '192.168.1.100'
dhcp_router: '192.168.1.1'
ipv6_address: ''
pihole_dns_1: '8.8.8.8'
pihole_dns_2: '8.8.4.4'
webpassword: 'this-password-should-not-stay-the-same'

# Wireguard Settings:
wireguard_interface: 'wg0'

# Additional Features
vpn: True
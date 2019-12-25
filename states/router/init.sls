include:
  - router.setup
  - router.hardening
  - router.firehol
  - router.pihole
  {% if pillar['enable_vpn'] %}
  - router.wireguard
  {% endif %}
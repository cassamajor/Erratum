include:
  - router.setup
  - router.hardening
  - router.firehol
  - router.pihole
  {% if pillar['vpn'] %}
  - router.wireguard
  {% endif %}
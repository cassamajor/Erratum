rock:
  salt.state:
    - tgt: '*'
    - sls:
      - router.rock

setup:
  salt.state:
    - tgt: '*'
    - sls:
      - router.setup

hardening:
  salt.state:
    - tgt: '*'
    - sls:
      - router.hardening

pihole:
  salt.state:
    - tgt: '*'
    - sls:
      - router.pihole

firehol:
  salt.state:
    - tgt: '*'
    - sls:
      - router.firehol

wireguard:
  salt.state:
    - tgt: '*'
    - sls:
      - router.wireguard
Configure Hostname:
  file.replace:
    - name: /etc/rocknsm/config.yml
    - pattern: 'rock_hostname: simplerockbuild'
    - repl: 'rock_hostname: {{ pillar['hostname'] }}'

Configure FQDN:
  file.replace:
    - name: /etc/rocknsm/config.yml
    - pattern: 'rock_fqdn: simplerockbuild.simplerock.lan'
    - repl: 'rock_fqdn: {{ pillar['hostname'] }}.{{ pillar['domain'] }}'

Enable Online Install:
  file.replace:
    - name: /etc/rocknsm/config.yml
    - pattern: 'rock_online_install: False'
    - repl: 'rock_online_install: True'

Elasticsearch Cluster Name:
  file.replace:
    - name: /etc/rocknsm/config.yml
    - pattern: 'es_node_name: simplerockbuild'
    - repl: 'es_node_name: {{ pillar['hostname'] }}'

deploy_rock:
  cmd.script:
    - name: /opt/rocknsm/rock/bin/deploy_rock.sh
    - cwd: /opt/rocknsm/rock/bin/
    - runas: root

start_rock:
  cmd.run:
    - name: rockctl start
    - runas: root

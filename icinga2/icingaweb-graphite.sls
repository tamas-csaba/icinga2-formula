
download-graphite-module:
  cmd.run:
    - name: "wget https://github.com/findmypast/icingaweb2-module-graphite/archive/master.zip && unzip master.zip && mv icingaweb2-module-graphite-master/ graphite"
    - cwd: /usr/share/icingaweb2/modules/
    - user: root
    - output_loglevel: DEBUG

module-config-file:
  file.managed:
    - name: /etc/icingaweb2/modules/graphite/config.ini
    - source: salt://icinga2/files/graphite_module_config.ini
    - makedirs: True
    - user: root
    - group: root
    - mode: 777


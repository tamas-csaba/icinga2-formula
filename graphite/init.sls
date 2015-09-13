graphite-required-packages:
  pkg.installed:
    - pkgs:
      - libaprutil1-ldap 
      - python-ldap 
      - memcached 
      - python-memcache 
      - python-pip 
      - build-essential 
      - python-dev 
      - libapache2-mod-wsgi 
      - python-cairo-dev

graphite-deps:
   cmd.run:
        - name: "easy_install django-tagging zope.interface twisted txamqp"
        - user: root
        - output_loglevel: DEBUG

dajango-removed:
  pkg.purged:
      - name: python-django

django-pip:
  pip.installed:
    - name: django == 1.7.2
    - require:
      - pkg: graphite-required-packages

whisper-pip:
  pip.installed:
    - name: whisper
    - user: root
    - require:
      - pkg: graphite-required-packages
      - cmd: graphite-deps

carbon-pip:
  pip.installed:
    - name: carbon
    - user: root
    - require:
      - pkg: graphite-required-packages
      - cmd: graphite-deps

graphite-pip:
  pip.installed:
    - name: graphite-web
    - user: root
    - require:
      - pkg: graphite-required-packages
      - cmd: graphite-deps

graphite-config:
  file.recurse:
    - name: /opt/graphite/conf/
    - source: salt://graphite/files/graphite_conf
    - makedirs: True
    - user: www-data
    - group: icingaweb2
    - dir_mode: 750
    - file_mode: 644

webapp-config:
  file.recurse:
    - name: /opt/graphite/webapp/graphite
    - source: salt://graphite/files/webapp_conf
    - makedirs: True
    - user: www-data
    - group: icingaweb2
    - dir_mode: 750
    - file_mode: 644

syncdb-cmd:
  cmd.run:
    - name: "python manage.py syncdb --noinput"
    - cwd: /opt/graphite/webapp/graphite/
    - user: root
    - output_loglevel: DEBUG
    - require:
      - file: webapp-config

syncdb-user-cmd:
  cmd.run:
    - name: "echo \"from django.contrib.auth.models import User; User.objects.create_superuser('admin', 'myemail@example.com', 'admin');\" | sudo python manage.py shell"
    - cwd: /opt/graphite/webapp/graphite/
    - user: root
    - output_loglevel: DEBUG
    - require:
      - file: webapp-config
      - cmd: syncdb-cmd

webowner-storage-cmd:
  cmd.run:
    - name: "chown -R www-data:www-data /opt/graphite/storage"
    - cwd: /opt/
    - user: root
    - output_loglevel: DEBUG
    - require:
      - file: webapp-config

wsgi-socket-setup-cmd:
  cmd.run:
    - name: "sudo mkdir -p /etc/httpd/wsgi"
    - cwd: /opt/
    - user: root
    - output_loglevel: DEBUG
    - require:
      - file: webapp-config


apache-setup:
  file.managed:
    - name: /etc/apache2/sites-available/default
    - source: salt://graphite/files/example-graphite-vhost.conf
    - user: root
  service.running:
    - name: apache2
    - restart: True
    - watch:
      - file: /etc/apache2/sites-available/default

service-script-file:
  file.managed:
    - name: /etc/init.d/carbon-cache
    - source: salt://graphite/files/carbon-cache
    - user: root
    - group: root
    - mode: 777

carbon-cache-service:
  service.running:
    - name: carbon-cache
    - enable: True
    - sig: "/usr/bin/python bin/carbon-cache.py"
    - require:
      - file: service-script-file
      - cmd: syncdb-user-cmd

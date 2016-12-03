# Inspired by https://github.com/nickstenning/docker-slapd
# and https://github.com/osixia/docker-openldap/

FROM ubuntu:xenial

RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install \
      ldap-utils \
      rsyslog \
      slapd \
      supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY run.sh /container/
COPY bin/* /usr/local/bin/

# Contains the ldap database as well as all relevant settings.
# This volume is the only part of the container that needs to be persistent.
VOLUME ["/data"]

# contains slapd's unix domain socket; sharing this volume allows to talk
# to slapd from another container
VOLUME ["/var/run/slapd"]

# Import:
# if a directory /import/ldif exists, then all LDIF files in it are applied on startup.
# The files are applied in alphabetical order, and only once.
# File names shall not contain spaces.

# TLS keys:
# If a directory is mounted under /config/cert and contains the files
# key.pem and crt.pem, then these files are used as TLS key and certificate (or certificate chain).

# Default values for initial setup of OpenLDAP
ENV LDAP_DOMAIN=example.com
ENV LDAP_ORGANIZATION=Example
ENV LDAP_ADMIN_PASSWORD=admin

# Per default the config database is accessible only locally
# Set these values to allow remote access as well.
# Se LDAP_CONFIG_DN *must* be under "cn=config"
ENV LDAP_CONFIG_DN=cn=admin,cn=config
ENV LDAP_CONFIG_PASSWORD=admin

# The log level. See http://www.openldap.org/doc/admin24/slapdconf2.html for details.
ENV LDAP_LOG_LEVEL=${LDAP_LOG_LEVEL:-256}

# Ports:
# 389: LDAP (unsecured or TLS-secured using STARTTLS)
# 636: LDAP (secured using TLS)
EXPOSE 389 636

CMD ["/container/run.sh"]

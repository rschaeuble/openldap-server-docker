# rschaeuble/openldap

An OpenLDAP docker image.


## Getting started

Run the image:
`docker run --name my-openldap -d -p 389:389 rschaeuble/openldap-server:latest`

This will start a new container with a running OpenLDAP daemon, exposing it on
port 389.

You can now connect to the server to see if it's working:
`ldapsearch -D cn=admin,dc=example,dc=com -w admin -h localhost -b "" -s base`


## Configuration

When the container is started for the first time, it configures slapd (the OpenLDAP daemon)
and creates the initial database. The required configuration (username, password, organization name)
are configured with default values in `Dockerfile`. For serious use, these values should
be overridden using environment variables (e.g. using the `--env` parameter of `docker run`).

The essential configuration parameters are:

| Parameter | Meaning | Default value |
| --------- | ------- | ------------- |
| LDAP_DOMAIN | Determines the name of the root entry of the database. \ A value of `example.com` will result in the root entry being named `dc=example,dc=com`| example.com |
| LDAP_ORGANIZATION | The name of the organization | Example |
| LDAP_ADMIN_PASSWORD | The password for the admin account. The name of the admin account is set automatically to `cn=admin,dc=example,dc=com` (assuming LDAP_DOMAIN=example.com) | admin |

Per default slapd's configuration database (`cn=config`) is accessible only locally (from inside the container). Remote access over TCP can be enabled by setting the following parameters:

| Parameter | Meaning |
| --------- | ------- |
| LDAP_CONFIG_DN | The Root DN to set for `cn=config`. This DN *must* be a child of `cn=config`, otherwise no access will be possible |
| LDAP_CONFIG_PASSWORD | The password for the Root DN |

Other configuration parameters:

| Parameter | Meaning |
| --------- | ------- |
| LDAP_LOG_LEVEL | The log level of slapd. See http://www.openldap.org/doc/admin24/slapdconf2.html for details.<br/>This can later be changed in /etc/supervisor/conf.d/supervisord.conf |


## Volumes

The `Dockerfile` creates the following volumes:

* */data*: This is where all "valuable" data is stored. This include slapd's configuration (/etc/ldap/) and the ldap databases (/var/lib/ldap/) as well as state maintained by the container.<br/>This volume can be bind-mounted into the container to keep the data on the host.
* */var/run/slapd: contains slapd's unix domain socket; sharing this volume allows to talk to slapd from another container.<br/>This volume does not need to be backed up.


## Importing LDIF files

If a directory `/import/ldif` exists (e.g. bind-mounted from the Docker host), then all LDIF files (*.ldif) in it are applied during startup. The files are applied in alphabetical order, and only once.<br/>File names shall not contains spaces!


## SSL

OpenLDAP supports secure connections using TLS. To use TLS, a private key and a certificate (or a whole certificate chain) needs to be provided.

These files can be supplied by bind-mounting a directory under `/config/cert`. This directory must contain two files:
* *key.pem*: the private key
* *crt.pem*: the certificate (and optionally the full certificate chain required to validate the certificate)

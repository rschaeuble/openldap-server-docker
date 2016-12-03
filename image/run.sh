#!/bin/bash

set -eu

# contains LDIF files to apply during startup
LDIF_DIR=/import/ldif

# tracks which LDIFs were already applied
LDIF_APPLIED=/data/state/ldif-applied.lst


function status () {
  echo "---> ${@}" >&2
}

function start_slapd() {
  status "Starting slapd"

  /usr/sbin/slapd -h "ldapi:///" -u openldap -g openldap -d 0 &
  SLAPD_PID=$!

  while ! ldap-status; do
    sleep 1
  done
}

function stop_slapd() {
  status "Stopping slapd"

  kill $SLAPD_PID
  wait $SLAPD_PID || true
}

function allow_remote_config_access() {
  local DN=$1
  local PASSWORD=$2

  status "Enabling remote access to config database"

  local PASSWORD_HASH=`slappasswd -s "$PASSWORD"`

  start_slapd

  cat <<EOF | ldapmodify -Y EXTERNAL -H ldapi:///
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootDn
olcRootDn: ${DN}
-
add: olcRootPW
olcRootPW: ${PASSWORD_HASH}
EOF

  stop_slapd
}

function apply_ldifs() {
  local LIST=/tmp/ldifs.lst

  # make sure file exists before using it
  touch $LDIF_APPLIED

  if [ -d "$LDIF_DIR" ]; then
    ls -1 "$LDIF_DIR" |  grep -v -f "$LDIF_APPLIED" | sort > $LIST
    if [ `cat $LIST | wc -l` -ne 0 ]; then
      status "Applying LDIF files"

      start_slapd

      for FILE in `cat $LIST`; do
        echo applying LDIF file $FILE
        ldapmodify -Y EXTERNAL -H ldapi:/// -f "$LDIF_DIR/$FILE"
        echo "$FILE" >> "$LDIF_APPLIED"
      done

      stop_slapd
    fi
  fi
}

# Prevent slapd from consuming too much memory
# See https://github.com/docker/docker/issues/8231 for details.
ulimit -n 1024

if [ ! -f /data/state/initialized ]; then
  status "initializing data directories"

  # One-time setup of data directories.
  mkdir -p /data/var/lib
  mv /var/lib/ldap /data/var/lib/
  ln -s /data/var/lib/ldap /var/lib/ldap

  mkdir -p /data/etc/ldap
  mv /etc/ldap /data/etc/
  ln -s /data/etc/ldap /etc/ldap

  mkdir -p /data/state

  status "configuring slapd for first run"

  debconf-set-selections <<EOF
          slapd slapd/password1 password ${LDAP_ADMIN_PASSWORD}
          slapd slapd/password2 password ${LDAP_ADMIN_PASSWORD}
          slapd slapd/domain string ${LDAP_DOMAIN}
          slapd shared/organization string ${LDAP_ORGANIZATION}
EOF

  dpkg-reconfigure -f noninteractive slapd

  if [[ "${LDAP_CONFIG_DN-}" != "" && "${LDAP_CONFIG_PASSWORD}" != "" ]]; then
    allow_remote_config_access "$LDAP_CONFIG_DN" "$LDAP_CONFIG_PASSWORD"
  fi

  touch /data/state/initialized
else
  status "slapd already configured"
fi

apply_ldifs

exec /usr/bin/supervisord

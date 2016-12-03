# Shared functions for backup and restore scripts

# Lists the suffixes of all LDAP databases.
function list_database_suffixes() {
  slapcat -b cn=config | sed -n -e 's/^olcSuffix: \(.*\)/\1/p'
}

# Sets the olcReadonly attribute of the specified LDAP database to the specified value.
function set_db_readwrite() {
  local DB=$1
  local READONLY=$2

  cat <<EOF | ldapmodify -Q -Y EXTERNAL -H ldapi:///
dn: $DB
changetype: modify
replace: olcReadonly
olcReadonly: $READONLY
EOF
}

# Makes the specified LDAP datbase read-only.
function make_db_readonly() {
  echo Making database $1 read-only
  set_db_readwrite $1 TRUE
}

# Makes the specified LDAP database read-write.
function make_db_readwrite() {
  echo Making database $1 writable
  set_db_readwrite $1 FALSE
}

# Finds the LDAP database with the specified suffix.
function find_db_with_suffix() {
  local SUFFIX=$1

  ldapsearch -H ldapi:// -Y EXTERNAL -b "cn=config" "(olcSuffix=$SUFFIX)" dn -LLL -Q |
    cut -d ' ' -f 2
}

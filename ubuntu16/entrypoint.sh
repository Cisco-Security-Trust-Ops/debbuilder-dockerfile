#!/bin/bash

#Exit immediately if a command returns a non-zero status
set -e

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

#If defined GPG_ID, then they want to sign RPMS
#You can pass in a file as GPG_KEY_FILE as it read a file from the container env
#TODO - We probaly need the bleow later, its just different for ubuntu
file_env 'GPG_KEY'
if [ -z "${GPG_KEY}" ]; then
  echo "GPG_KEY not defined; not setting state for signing debian packages" 1>&2
  #envsubst < /tmp/rpmmacros_nosign.template > ${HOME}/.rpmmacros
else
  if [ -z "${GPG_KEY_ID}" ]; then
    echo "GPG_KEY defined, but missing the GPG_KEY_ID required to set up the environment"
    exit 1
  fi
  #If using a development environment, it may be that we already have existing key.  Do
  #let's delete it from the key ring and add in the update
  set +e
  if [[ $(gpg --list-keys | grep -w ${GPG_KEY_ID}) ]]; then
    set -e
    fingerprint=`gpg --list-secret-keys --with-colons --fingerprint | grep ${GPG_KEY_ID} | sed -n 's/^fpr:::::::::\([[:alnum:]]\+\):/\1/p'`
    echo "Delete old key ${GPG_KEY_ID} with fingerprint ${fingerprint}"
    gpg --delete-secret-keys --batch ${fingerprint}
  fi
  set -e
  echo "${GPG_KEY}" > /tmp/gpg.key
  echo "Importing gpg key"
  gpg --allow-secret-key-import --import /tmp/gpg.key > /dev/null 2>&1
  #echo "Envsubst, porting template over to rpmmacros"
  #envsubst < /tmp/rpmmacros_sign.template > ${HOME}/.rpmmacros
  unset GPG_KEY
  rm /tmp/gpg.key
fi

if [ `id -u` -gt 0 ]; then

  export USER_ID=`id -u`
  export GROUP_ID=`id -g`
  envsubst < /tmp/passwd.template > ${NSS_WRAPPER_PASSWD}
  envsubst < /tmp/group.template > ${NSS_WRAPPER_GROUP}
  export LD_PRELOAD=libnss_wrapper.so
fi

exec "$@"

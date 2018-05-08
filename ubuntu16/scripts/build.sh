#!/bin/bash

set -e

usage ()
{
    cat <<- _EOF_

#########################################################################################
 Options:
 -h or --help              Display the HELP message and exit.
 --sign_rpms               Sign the rpms at the end.  This calls sign_rpms.py which requires a
                           the GPG_PASSPHRASE to be in the environment
 --x32                     Build 32 bit
 --x64                     Build 64 bit (Default)
 --no_clean                Forces the BUILD directory to not be deleted
_EOF_
}

#set default interation
SIGN_RPMS=false
ARCH="x64"
CLEAN_BUILD=true

for i in "$@"
do
  case $i in
    --sign_rpms)
      SIGN_RPMS=true
      shift
    ;;
    --x64)
    ARCH="x64"
    shift
    ;;
    --x32)
    ARCH="x32"
    shift
    ;;
    --no-clean)
    CLEAN_BUILD=false
    shift
    ;;
    -h | --help)
      usage
      exit
    ;;
    *)
      echo "Unknown option: $i"
      exit 1
    ;;
  esac
done

#set variables for relative path
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
ROOT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )

#set build variables
VERSION_NUMBER=$(cat ${ROOT_DIR}/build.properties | grep ^VERSION | awk -F'[=]' '{print $2}')
SOURCE_BASE_URL=$(cat ${ROOT_DIR}/build.properties | grep ^SOURCE_BASE_URL | awk -F'[=]' '{print $2}')
PROJECT_NAME=$(cat ${ROOT_DIR}/build.properties | grep ^PROJECT_NAME | awk -F'[=]' '{print $2}')
SOURCE_NAME=${PROJECT_NAME}-${VERSION_NUMBER}

#clean build directory unless specified otherwise, recreate
if [ ${CLEAN_BUILD} = true ]; then
  rm -rf  ${ROOT_DIR}/BUILD
fi
if [ ! -d ${ROOT_DIR}/BUILD/${PROJECT_NAME} ]; then
  mkdir -p ${ROOT_DIR}/BUILD/${PROJECT_NAME}
fi
cd ${ROOT_DIR}/BUILD

#download and untar
if [ ! -f ${SOURCE_NAME}.tar.gz ]; then
	wget ${SOURCE_BASE_URL}/${SOURCE_NAME}.tar.gz
fi
tar -zxvf ${SOURCE_NAME}.tar.gz --strip 1 -C ${PROJECT_NAME}

#get the debian dir for supporting our build
cd ${ROOT_DIR}
cp -R debian BUILD/${PROJECT_NAME}

#create the binary
cd ${ROOT_DIR}/BUILD/${PROJECT_NAME}
if [ "$ARCH" = "x64" ]; then
  dpkg-buildpackage -b | tee ~/x64_txt.out 2>&1
elif [ "$ARCH" = "x32" ]; then
  dpkg-buildpackage -b -ai386 | tee ~/x32_txt.out 2>&1
else
  echo "Unknown arch $ARCH"
fi

#copy *.deb and *.udeb artifacts for upload later on
cd ${ROOT_DIR}/BUILD
mkdir -p ${ROOT_DIR}/artifacts/${ARCH}
mv *deb ${ROOT_DIR}/artifacts/${ARCH}

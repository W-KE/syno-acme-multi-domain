#!/bin/bash

# path of this script
BASE_ROOT=$(cd "$(dirname "$0")";pwd)
# date time
DATE_TIME=`date +%Y%m%d%H%M%S`
# base crt path
CRT_BASE_PATH="/usr/syno/etc/certificate"
PKG_CRT_BASE_PATH="/usr/local/etc/certificate"
#CRT_BASE_PATH="/Users/carl/Downloads/certificate"
ACME_BIN_PATH=${BASE_ROOT}/acme.sh
TEMP_PATH=${BASE_ROOT}/temp

backupCrt () {
  echo "[INFO] begin backupCrt"
  BACKUP_PATH=${BASE_ROOT}/backup/${DATE_TIME}
  mkdir -p ${BACKUP_PATH}
  cp -r ${CRT_BASE_PATH} ${BACKUP_PATH}
  cp -r ${PKG_CRT_BASE_PATH} ${BACKUP_PATH}/package_cert
  echo ${BACKUP_PATH} > ${BASE_ROOT}/backup/latest
  echo "[INFO] done backupCrt"
  return 0
}

installAcme () {
  echo "[INFO] begin installAcme"
  mkdir -p ${TEMP_PATH}
  cd ${TEMP_PATH}
  echo "[INFO] begin downloading acme.sh tool..."
  ACME_SH_ADDRESS=`curl -L https://cdn.jsdelivr.net/gh/andyzhshg/syno-acme@master/acme.sh.address`
  SRC_TAR_NAME=acme.sh.tar.gz
  curl -L -o ${SRC_TAR_NAME} ${ACME_SH_ADDRESS}
  SRC_NAME=`tar -tzf ${SRC_TAR_NAME} | head -1 | cut -f1 -d"/"`
  tar zxvf ${SRC_TAR_NAME}
  echo "[INFO] begin installing acme.sh tool..."
  cd ${SRC_NAME}
  ./acme.sh --install --nocron --home ${ACME_BIN_PATH}
  echo "[INFO] done installAcme"
  rm -rf ${TEMP_PATH}
  return 0
}

generateCrts () {
  echo "[INFO] begin generateCrt for all domains"
  cd ${BASE_ROOT}
  source config
  /bin/python2 ${BASE_ROOT}/cert_info.py ${DOMAIN}
  source domains
  DOMAINS_COUNT=$((DOMAINS_COUNT - 1))
  for i in $(seq 0 $DOMAINS_COUNT);
    do generateCrt ${DOMAINS[i]} ${DOMAINS_HASHES[i]};
  done
}

generateCrt () {
  echo "[INFO] begin generateCrt"
  cd ${BASE_ROOT}
  source config
  CRT_PATH=${CRT_BASE_PATH}/_archive/$2
  echo "[INFO] begin updating default cert by acme.sh tool"
  source ${ACME_BIN_PATH}/acme.sh.env
  ${ACME_BIN_PATH}/acme.sh --force --log --issue --dns ${DNS} --dnssleep ${DNS_SLEEP} -d "$1" -d "*.$1"
  ${ACME_BIN_PATH}/acme.sh --force --installcert -d $1 -d *.$1 \
    --certpath ${CRT_PATH}/cert.pem \
    --key-file ${CRT_PATH}/privkey.pem \
    --fullchain-file ${CRT_PATH}/fullchain.pem

  if [ -s "${CRT_PATH}/cert.pem" ]; then
    echo "[INFO] done generateCrt"
    return 0
  else
    echo "[ERROR] fail to generateCrt"
    echo "[INFO] begin revert"
    revertCrt
    exit 1;
  fi
}

updateService () {
  echo "[INFO] begin updateService"
  echo "cp cert path to des"
  /bin/python2 ${BASE_ROOT}/cert_cp.py
  echo "[INFO] done updateService"
}

reloadWebService () {
  echo "[INFO] begin reloadWebService"
  echo "[INFO] reloading new cert..."
  /usr/syno/etc/rc.sysv/nginx.sh reload
  echo "[INFO] relading Apache 2.2"
  stop pkg-apache22
  start pkg-apache22
  reload pkg-apache22
  echo "[INFO] done reloadWebService"
}

revertCrt () {
  echo "[INFO] begin revertCrt"
  BACKUP_PATH=${BASE_ROOT}/backup/$1
  if [ -z "$1" ]; then
    BACKUP_PATH=`cat ${BASE_ROOT}/backup/latest`
  fi
  if [ ! -d "${BACKUP_PATH}" ]; then
    echo "[ERROR] backup path: ${BACKUP_PATH} not found."
    return 1
  fi
  echo "[INFO] ${BACKUP_PATH}/certificate ${CRT_BASE_PATH}"
  cp -rf ${BACKUP_PATH}/certificate/* ${CRT_BASE_PATH}
  echo "[INFO] ${BACKUP_PATH}/package_cert ${PKG_CRT_BASE_PATH}"
  cp -rf ${BACKUP_PATH}/package_cert/* ${PKG_CRT_BASE_PATH}
  reloadWebService
  echo "[INFO] done revertCrt"
}

updateCrt () {
  echo "------ begin updateCrt ------"
  backupCrt
  installAcme
  generateCrts
  updateService
  reloadWebService
  echo "------ end updateCrt ------"
}

case "$1" in
  update)
    echo "[INFO] begin update cert"
    updateCrt
    ;;

  revert)
    echo "[INFO] begin revert"
      revertCrt $2
      ;;

    *)
        echo "Usage: $0 {update|revert}"
        exit 1
esac
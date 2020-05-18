import shutil
import sys

from cert_info import get_info

CERT_FILES = [
    "cert.pem",
    "privkey.pem",
    "fullchain.pem"
]

CERT_BASE_PATH = "/usr/syno/etc/certificate"
PKG_CERT_BASE_PATH = "/usr/local/etc/certificate"

ARCHIVE_PATH = CERT_BASE_PATH + "/_archive"
INFO_FILE_PATH = ARCHIVE_PATH + "/INFO"

info = get_info()
if not info:
    sys.exit(1)

for SRC_DIR_NAME in info:
    if info[SRC_DIR_NAME]["desc"]:
        print "[INFO] Copying cert for domain {}".format(info[SRC_DIR_NAME]["desc"])
    else:
        print "[INFO] Copying cert for Default domain"
    CP_FROM_DIR = ARCHIVE_PATH + "/" + SRC_DIR_NAME
    for service in info[SRC_DIR_NAME]["services"]:
        print "[INFO] Copying cert for service {}".format(service["display_name"])
        if service["isPkg"]:
            CP_TO_DIR = "{}/{}/{}".format(PKG_CERT_BASE_PATH, service["subscriber"], service["service"])
        else:
            CP_TO_DIR = "{}/{}/{}".format(CERT_BASE_PATH, service["subscriber"], service["service"])
        for f in CERT_FILES:
            src = CP_FROM_DIR + "/" + f
            des = CP_FROM_DIR + "/" + f
            try:
                shutil.copy2(src, des)
            except:
                print "[WARNING] Copy from {} to {} failed".format(src, des)

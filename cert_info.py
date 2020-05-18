import json
import sys

CERT_BASE_PATH = "/usr/syno/etc/certificate"
ARCHIVE_PATH = CERT_BASE_PATH + "/_archive"
INFO_FILE_PATH = ARCHIVE_PATH + "/INFO"


def get_info():
    try:
        with open(INFO_FILE_PATH) as fp:
            info = json.load(fp)
    except:
        print "[ERROR] failed loading INFO file at {}".format(INFO_FILE_PATH)
        return []
    return info


if __name__ == "__main__":
    default_domain = sys.argv[1]
    info = get_info()
    if not info:
        sys.exit(1)
    domains = []
    domain_hashes = []
    for domain_hash in info:
        domain_hashes.append(domain_hash)
        if info[domain_hash]["desc"]:
            domains.append(info[domain_hash]["desc"])
        else:
            domains.append(default_domain)
    count_string = "export DOMAINS_COUNT={}".format(len(info))
    domains_string = "export DOMAINS=({})".format(" ".join(domains))
    domain_hashes_string = "export DOMAINS_HASHES=({})".format(" ".join(domain_hashes))
    with open("domains", "w+") as fp:
        fp.write("{}\n{}\n{}".format(count_string, domains_string, domain_hashes_string))

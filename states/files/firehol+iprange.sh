#!/usr/bin/env bash

download() {
	url="${1}"
	dest="${2}"
	if command -v curl >/dev/null 2>&1; then
		curl -sSL --connect-timeout 10 --retry 3 "${url}" >"${dest}" || fatal "Cannot download ${url}"
	elif command -v wget >/dev/null 2>&1; then
		wget -T 15 -O - "${url}" >"${dest}" || fatal "Cannot download ${url}"
	else
		fatal "I need curl or wget to proceed, but neither is available on this system."
	fi
}


set_package_urls() {
    build_date=$(download "https://api.github.com/repos/firehol/packages/releases/latest" /dev/stdout | grep tag_name | cut -d'"' -f4)

    iprange_version=$(download "https://api.github.com/repos/firehol/iprange/releases/latest" /dev/stdout | grep tag_name | cut -d'"' -f4)
    iprange_version=${iprange_version//v/}
    export IPRANGE_URL="https://github.com/firehol/packages/releases/download/$build_date/iprange-$iprange_version-1.el7.x86_64.rpm"

    firehol_version=$(download "https://api.github.com/repos/firehol/firehol/releases/latest" /dev/stdout | grep tag_name | cut -d'"' -f4)
    firehol_version=${firehol_version//v/}
    export FIREHOL_URL="https://github.com/firehol/packages/releases/download/$build_date/firehol-$firehol_version-1.el7.noarch.rpm"

}

TMPDIR='/srv/states/files/'
# cd "${TMPDIR}"
set_package_urls
download "${IPRANGE_URL}" "${TMPDIR}/iprange-latest.rpm"
download "${FIREHOL_URL}" "${TMPDIR}/firehol-latest.rpm"

# yum --nogpgcheck localinstall iprange-latest.rpm
# yum --nogpgcheck localinstall firehol-latest.rpm
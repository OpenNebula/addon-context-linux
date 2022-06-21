#!/usr/bin/env bash

# -------------------------------------------------------------------------- #
# Copyright 2002-2022, OpenNebula Project, OpenNebula Systems                #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

# shellcheck disable=SC1091

if [ -z "${TARGET}" ]; then
    echo 'Error: env. variable TARGET not set' >&2
    exit 1
fi

set -e
source targets.sh
set +e

###

if [ -z "${RELEASE}" ]; then
    if git describe --contains "$(git rev-parse HEAD)" &>/dev/null; then
        RELEASE=1
    else
        DATE=${DATE:-$(date +%Y%m%d)}
        GIT=$(git rev-parse --short HEAD)
        RELEASE="0.${DATE}git${GIT}"
    fi
fi

###

VERSION=${VERSION:-6.4.1}
RELEASE=${RELEASE:-1}
MAINTAINER=${MAINTAINER:-OpenNebula Systems <contact@opennebula.io>}
LICENSE=${LICENSE:-Apache 2.0}
VENDOR=${VENDOR:-OpenNebula Systems}
SUMMARY="OpenNebula Contextualization Package"
DESC="
Contextualization tools for the virtual machine running in the OpenNebula
cloud. Based on parameters provided by the cloud controller configures the
networking, initial user password, SSH keys, runs custom start scripts,
resizes the root filesystem, and provides tools to communicate with
OneGate service.

Check the OpenNebula web page (http://opennebula.org) to get the support.
"
DESCRIPTION=${DESCRIPTION:-$DESC}
URL=${URL:-http://opennebula.org}
RELEASE_FULL="${RELEASE}${RELSUFFIX}"
EXT="${EXT:-${TYPE}}"

if [ "${TYPE}" = 'deb' ]; then
    FILENAME="${NAME}_${VERSION}-${RELEASE_FULL}.${EXT}"
elif [ "${TYPE}" = 'apk' ]; then
    RELEASE_FULL="r${RELEASE_FULL}"
    FILENAME="${NAME}-${VERSION}-${RELEASE_FULL}.${EXT}"
elif [ "${TARGET}" = 'arch' ]; then
    FILENAME="${NAME}-${VERSION}-${RELEASE_FULL}-any.${EXT}"
elif [ "${TARGET}" = 'freebsd' ]; then
    FILENAME="${NAME}-${VERSION}_${RELEASE_FULL}.${EXT}"
elif [ "${TARGET}" = 'alt' ]; then
    RELEASE_FULL="${RELSUFFIX}${RELEASE}"
    FILENAME="${NAME}-${VERSION}-${RELEASE_FULL}.noarch.${EXT}"
elif [ "${TYPE}" = 'iso' ]; then
    LABEL="${NAME}-${VERSION}"
    FILENAME="${NAME}-${VERSION}-${RELEASE_FULL}.${EXT}"
else
    FILENAME="${NAME}-${VERSION}-${RELEASE_FULL}.noarch.${EXT}"
fi

###

set -e

UNAME_PATH=$(mktemp -d)
BUILD_DIR=$(mktemp -d)

_POSTIN=$(mktemp)
_PREUN=$(mktemp)
_POSTUN=$(mktemp)
_POSTUP=$(mktemp)

# shellcheck disable=SC2064
trap "rm -rf ${UNAME_PATH} ${BUILD_DIR} ${_POSTIN} ${_PREUN} ${_POSTUN} ${_POSTUP}" EXIT

while IFS= read -r -d $'\0' SRC; do
    F_TAGS=${SRC##*##}
    if [ "x${SRC}" != "x${F_TAGS}" ]; then
        # shellcheck disable=SC2001
        for F_TAG in $(echo "${F_TAGS}" | sed -e 's/\./ /g'); do
            for TAG in ${TAGS}; do
                if [ "${F_TAG}" = "${TAG}" ]; then
                    continue 2 # tag matches, continue with next tag
                fi
            done
            continue 2 # tags not maching, skip this file
        done
    fi

    # file matches
    DST=${SRC%##*} #strip tags
    mkdir -p "${BUILD_DIR}/$(dirname "${DST}")"
    cp "src/${SRC}" "${BUILD_DIR}/${DST}"
done < <(cd src/ &&  find . -type f -print0)

for F in "$@"; do
    cp -r "$F" "${BUILD_DIR}/"
done

# fix permissions and set umask for fpm
find "${BUILD_DIR}/" -perm -u+r -exec chmod go+r {} \;
find "${BUILD_DIR}/" -perm -u+x -exec chmod go+x {} \;
umask 0022

# cleanup
if [ -z "${OUT}" ]; then
    OUT="out/${FILENAME}"
    _out_dir=$(dirname "${OUT}")
    mkdir -p "${_out_dir}"
    rm -rf "${OUT}"
fi

# Mocked 'uname' to fake FreeBSD on Linux build systems.
# Otherwise FPM places Linux identification into TXZ packages.
if [ "${TYPE}" = 'freebsd' ] && [ ! -x /bin/freebsd-version ]; then
    cat - <<EOF >"${UNAME_PATH}/uname"
#!/bin/sh
[ "\$1" = '-s' ] && echo 'FreeBSD'
[ "\$1" = '-r' ] && echo '12.0-RELEASE'
EOF

    chmod +x "${UNAME_PATH}/uname"
    export PATH="${UNAME_PATH}:${PATH}"
fi

if [ "${TYPE}" = 'dir' ]; then
    cp -rT "${BUILD_DIR}" "${OUT}"

elif [ "${TYPE}" = 'iso' ]; then
    _out_dir=$(dirname "${OUT}")
    mkisofs -J -R -input-charset utf8 \
        -m '*.iso' \
        -V "${LABEL}" \
        -o "${OUT}" \
        "${_out_dir}"

else
    CONFIG_FILES=$(cd "${BUILD_DIR}" && \
        find etc/ \
            ! -path 'etc/one-context.d/*' \
            ! -path 'etc/init*' \
            -type f -printf '--config-files %p ')

    # concatenate pre/postinstall scripts
    if [ -n "${POSTIN}" ]; then
        cat "${POSTIN}" >"${_POSTIN}"
    fi

    if [ -n "${PREUN}" ]; then
        cat "${PREUN}" >"${_PREUN}"
    fi

    if [ -n "${POSTUN}" ]; then
        cat "${POSTUN}" >"${_POSTUN}"
    fi

    if [ -n "${POSTUP}" ]; then
        cat "${POSTUP}" >"${_POSTUP}"
    fi

    # set the package version of onesysprep
    sed -i "s/\<_PACKAGE_VERSION_\>/${VERSION}/" \
        "${BUILD_DIR}/usr/sbin/onesysprep"

    # shellcheck disable=SC2086
    fpm --name "${NAME}" --version "${VERSION}" --iteration "${RELEASE_FULL}" \
        --architecture all --license "${LICENSE}" \
        --vendor "${VENDOR}" --maintainer "${MAINTAINER}" \
        --description "${DESCRIPTION}" --url "${URL}" \
        --output-type "${TYPE}" --input-type dir --chdir "${BUILD_DIR}" \
        --directories /etc/one-context.d \
        ${POSTIN:+ --after-install ${_POSTIN}} \
        ${POSTUP:+ --after-upgrade ${_POSTUP}} \
        ${PREUN:+ --before-remove ${_PREUN}} \
        ${POSTUN:+ --after-remove ${_POSTUN}} \
        --rpm-os linux \
        --rpm-summary "${SUMMARY}" \
        ${DEPENDS:+ --depends ${DEPENDS// / --depends }} \
        ${RECOMMENDS:+ --rpm-tag Recommends:${RECOMMENDS// / --rpm-tag Recommends:}} \
        ${RECOMMENDS:+ --deb-recommends ${RECOMMENDS// / --deb-recommends }} \
        ${REPLACES:+ --replaces ${REPLACES// / --replaces }} \
        ${CONFLICTS:+ --conflicts ${CONFLICTS// / --conflicts }} \
        ${PROVIDES:+ --provides ${PROVIDES// / --provides }} \
        --deb-no-default-config-files \
        --pacman-user 0 \
        --pacman-group 0 \
        ${CONFIG_FILES} \
        --package "${OUT}"
fi

basename "${OUT}"

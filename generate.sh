#!/bin/bash

# -------------------------------------------------------------------------- #
# Copyright 2010-2017, OpenNebula Systems                                    #
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

if [ -z "${TARGET}" ]; then
    echo 'Error: env. variable TARGET not set' >&2
    exit 1
fi

set -e
source targets.sh
set +e

VERSION=${VERSION:-5.4.0}
RELEASE=${RELEASE:-1}
MAINTAINER=${MAINTAINER:-OpenNebula Systems <support@opennebula.systems>}
LICENSE=${LICENSE:-Apache 2.0}
VENDOR=${VENDOR:-OpenNebula Systems}
SUMMARY="OpenNebula Contextualization Package"
DESC="
This package prepares a VM image for OpenNebula:
  * Disables udev net and cd persistent rules
  * Deletes udev net and cd persistent rules
  * Unconfigures the network
  * Adds OpenNebula contextualization scripts to startup
    * Configure network
    * Configure dns (from DNS and ETH*_DNS context variables)
    * Set root authorized keys (from SSH_PUBLIC_KEY and EC2_PUBLIC_KEY)
  * Add onegate tool (NEEDS RUBY AND JSON GEM TO WORK)
  * Resize root filesystem
  * Generate host ssh keys in debian distributions

To get support check the OpenNebula web page:
  http://OpenNebula.org
"
DESCRIPTION=${DESCRIPTION:-$DESC}
URL=${URL:-http://opennebula.org}
RELEASE_FULL="${RELEASE}${RELSUFFIX}"

if [ "${TYPE}" = 'deb' ]; then
    FILENAME="${NAME}_${VERSION}-${RELEASE_FULL}.${TYPE}"
else
    FILENAME="${NAME}-${VERSION}-${RELEASE_FULL}.noarch.${TYPE}"
fi

###

set -e

BUILD_DIR=$(mktemp -d)
trap "rm -rf ${BUILD_DIR}" EXIT

while IFS= read -r -d $'\0' SRC; do
    F_TAGS=${SRC##*##}
    if [ "x${SRC}" != "x${F_TAGS}" ]; then
        for F_TAG in $(echo ${F_TAGS} | sed -e 's/\./ /g'); do
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

for F in $@; do
    cp -r "$F" "${BUILD_DIR}/"
done

# fix permissions and set umask for fpm
find "${BUILD_DIR}/" -perm -u+r -exec chmod go+r {} \;
find "${BUILD_DIR}/" -perm -u+x -exec chmod go+x {} \;
umask 0022

# cleanup
if [ -z "${OUT}" ]; then
    OUT="out/${FILENAME}"
    mkdir -p $(dirname "${OUT}")
    rm -rf "${OUT}"
fi

if [ "${TYPE}" = 'dir' ]; then
    cp -rT "${BUILD_DIR}" "${OUT}"
else
    fpm --name "${NAME}" --version "${VERSION}" --iteration "${RELEASE_FULL}" \
        --architecture all --license "${LICENSE}" \
        --vendor "${VENDOR}" --maintainer "${MAINTAINER}" \
        --description "${DESCRIPTION}" --url "${URL}" \
        --output-type "${TYPE}" --input-type dir --chdir "${BUILD_DIR}" \
        ${POSTIN:+ --after-install ${POSTIN}} \
        ${PREUN:+ --before-remove ${PREUN}} \
        --rpm-os linux \
        --rpm-summary "${SUMMARY}" \
        ${DEPENDS:+ --depends ${DEPENDS// / --depends }} \
        --replaces "${REPLACES}" \
        --conflicts "${REPLACES}" \
        --package "${OUT}"
#        --provides "${REPLACES}" \
fi

echo $(basename ${OUT})

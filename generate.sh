#!/bin/bash

# -------------------------------------------------------------------------- #
# Copyright 2010-2016, OpenNebula Systems                                    #
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

ENVIRONMENT=${ENVIRONMENT:-one}

if [ $ENVIRONMENT != "one" ]; then
    DEFAULT_NAME="one-context-$ENVIRONMENT"
else
    DEFAULT_NAME="one-context"
fi

VERSION=${VERSION:-4.90.0}
MAINTAINER=${MAINTAINER:-OpenNebula Systems <support@opennebula.systems>}
LICENSE=${LICENSE:-Apache 2.0}
PACKAGE_NAME=${PACKAGE_NAME:-$DEFAULT_NAME}
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
PACKAGE_TYPE=${PACKAGE_TYPE:-deb}
URL=${URL:-http://opennebula.org}

[ $PACKAGE_TYPE = rpm ] && PKGARGS="--rpm-os linux"

SCRIPTS_DIR=$PWD
NAME="${PACKAGE_NAME}_${VERSION}.${PACKAGE_TYPE}"
rm $NAME

rm -rf tmp
mkdir tmp

cp -r base/* tmp
test -d base.$ENVIRONMENT && cp -r base.$ENVIRONMENT/* tmp

cp -r base_$PACKAGE_TYPE/* tmp
test -d base_$PACKAGE_TYPE.$ENVIRONMENT && \
    cp -r base_$PACKAGE_TYPE.$ENVIRONMENT/* tmp

for i in $*; do
  cp -r "$i" tmp
done

if [ -f "postinstall.$ENVIRONMENT" ]; then
    POSTINSTALL="postinstall.$ENVIRONMENT"
else
    POSTINSTALL="postinstall.one"
fi

cd tmp

fpm -n "$PACKAGE_NAME" -t "$PACKAGE_TYPE" $PKGARGS -s dir --vendor "$VENDOR" \
    --license "$LICENSE" --description "$DESCRIPTION" --url "$URL" \
    -m "$MAINTAINER" -v "$VERSION" --after-install $SCRIPTS_DIR/$POSTINSTALL \
    -a all -p $SCRIPTS_DIR/$NAME --rpm-summary "$SUMMARY" *

echo $NAME



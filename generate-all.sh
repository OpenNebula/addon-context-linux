#!/bin/bash

set -e

export DATE=$(date +%Y%m%d)
TARGETS='el6 el7 el7_ec2 el8 el8_ec2 suse deb deb_ec2 alpine freebsd iso'

for TARGET in $TARGETS; do
	TARGET="${TARGET}" ./generate.sh
done

echo
echo "The packages are here:"
echo "--------------------------------------------------------------------------------"
find out -type f

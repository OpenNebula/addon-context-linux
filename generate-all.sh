#!/bin/bash

set -e

export DATE=$(date +%Y%m%d)
TARGETS='el6 el7 el8 alt suse deb alpine freebsd iso'

for TARGET in $TARGETS; do
	TARGET="${TARGET}" ./generate.sh
done

echo
echo "The packages are here:"
echo "--------------------------------------------------------------------------------"
find out -type f

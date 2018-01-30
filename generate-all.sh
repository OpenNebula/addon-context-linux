TARGETS='el6 el7 el7_ec2 suse deb deb_ec2 alpine iso'

set -e

for TARGET in $TARGETS; do
	TARGET="${TARGET}" ./generate.sh
done

echo
echo "The packages are here:"
echo "--------------------------------------------------------------------------------"
find out -type f

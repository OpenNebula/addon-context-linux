ENVIRONMENT=one PACKAGE_TYPE=deb ./generate.sh
ENVIRONMENT=one PACKAGE_TYPE=rpm ./generate.sh
ENVIRONMENT=ec2 PACKAGE_TYPE=deb ./generate.sh
ENVIRONMENT=ec2 PACKAGE_TYPE=rpm ./generate.sh

echo
echo "The packages are here:"
echo "--------------------------------------------------------------------------------"
find out -type f

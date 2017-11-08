case "${TARGET}" in
    'el6')
        NAME=${NAME:-one-context}
        RELSUFFIX=${RELSUFFIX:-.el6}
        TYPE=${TYPE:-rpm}
        TAGS=${TAGS:-rpm sysv one}
        DEPENDS=${DEPENDS:-util-linux-ng bind-utils cloud-utils-growpart dracut-modules-growroot ruby rubygem-json sudo open-vm-tools qemu-guest-agent}
        REPLACES=${REPLACES:-cloud-init}
        POSTIN=${POSTINST:-postinstall.one}
        PREUN=${PREUN:-preuninstall.one}
        ;;


    'el6_ec2')
        NAME=${NAME:-one-context-ec2}
        RELSUFFIX=${RELSUFFIX:-.el6}
        TYPE=${TYPE:-rpm}
        TAGS=${TAGS:-rpm sysv ec2}
        DEPENDS=${DEPENDS:-util-linux-ng bind-utils cloud-utils-growpart dracut-modules-growroot ruby rubygem-json sudo}
        REPLACES=${REPLACES:-cloud-init}
        POSTIN=${POSTINST:-postinstall.ec2}
        PREUN=${PREUN:-preuninstall.ec2}
        ;;

    'el7')
        NAME=${NAME:-one-context}
        RELSUFFIX=${RELSUFFIX:-.el7}
        TYPE=${TYPE:-rpm}
        TAGS=${TAGS:-rpm systemd one}
        DEPENDS=${DEPENDS:-util-linux bind-utils cloud-utils-growpart ruby rubygem-json sudo open-vm-tools qemu-guest-agent}
        REPLACES=${REPLACES:-cloud-init}
        POSTIN=${POSTINST:-postinstall.one}
        PREUN=${PREUN:-preuninstall.one}
        ;;

    'el7_ec2')
        NAME=${NAME:-one-context-ec2}
        RELSUFFIX=${RELSUFFIX:-.el7}
        TYPE=${TYPE:-rpm}
        TAGS=${TAGS:-rpm sysv ec2}
        DEPENDS=${DEPENDS:-util-linux bind-utils cloud-utils-growpart ruby rubygem-json sudo}
        REPLACES=${REPLACES:-cloud-init}
        POSTIN=${POSTINST:-postinstall.ec2}
        PREUN=${PREUN:-preuninstall.ec2}
        ;;

    'suse')
        NAME=${NAME:-one-context}
        RELSUFFIX=${RELSUFFIX:-.suse}
        TYPE=${TYPE:-rpm}
        TAGS=${TAGS:-rpm systemd one}
        DEPENDS=${DEPENDS:-util-linux bind-utils growpart ruby sudo open-vm-tools qemu-guest-agent} # rubygem-json}
        REPLACES=${REPLACES:-cloud-init cloud-init-config-suse}
        POSTIN=${POSTINST:-postinstall.one}
        PREUN=${PREUN:-preuninstall.one}
        ;;

    'deb')
        NAME=${NAME:-one-context}
        RELSUFFIX=${RELSUFFIX:-}
        TYPE=${TYPE:-deb}
        TAGS=${TAGS:-deb sysv systemd upstart one}
        DEPENDS=${DEPENDS:-util-linux bind9-host cloud-utils ruby python ifupdown acpid sudo open-vm-tools qemu-guest-agent}
        REPLACES=${REPLACES:-cloud-init}
        POSTIN=${POSTINST:-postinstall.one}
        PREUN=${PREUN:-preuninstall.one}
        ;;

    'deb_ec2')
        NAME=${NAME:-one-context-ec2}
        RELSUFFIX=${RELSUFFIX:-}
        TYPE=${TYPE:-deb}
        TAGS=${TAGS:-deb ec2}
        DEPENDS=${DEPENDS:-util-linux bind9-host cloud-utils ruby python ifupdown sudo}
        REPLACES=${REPLACES:-cloud-init}
        POSTIN=${POSTINST:-postinstall.ec2}
        PREUN=${PREUN:-preuninstall.ec2}
        ;;

    'alpine')
        NAME=${NAME:-one-context}
        RELSUFFIX=${RELSUFFIX:-}
        TYPE=${TYPE:-apk}
        TAGS=${TAGS:-apk one}
        DEPENDS=${DEPENDS:-util-linux bash curl rsync udev iptables sfdisk e2fsprogs-extra open-vm-tools qemu-guest-agent keepalived quagga sudo}
        REPLACES=${REPLACES:-}
        POSTIN=${POSTINST:-postinstall.one}
        PREUN=${PREUN:-preuninstall.one}
        ;;

    'arch')
        NAME=${NAME:-one-context}
        TYPE=${TYPE:-dir}
        TAGS=${TAGS:-arch one}
        ;;

    *)
        echo "Invalid target ${TARGET}"
        exit 1
esac

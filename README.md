# Linux VM Contextualization

These are the source of the contextualization packages used by VM to be
configured with the information generated by OpenNebula. This add-on is
compatible with OpenNebula >= 4.6.

## Get packages

Latest versions can be downloaded from the
[release page](https://github.com/OpenNebula/addon-context-linux/releases).

## Tested platforms

| Platform                            | Versions                               |
|-------------------------------------|----------------------------------------|
| CentOS                              | 6, 7                                   |
| Red Hat Enterprise Linux            | 7                                      |
| Fedora                              | 28, 29                                 |
| openSUSE                            | 42.3, 15                               |
| SUSE Linux Enterprise Server (SLES) | 12 SP3                                 |
| Debian                              | 8, 9, 10                               |
| Devuan                              | 1, 2                                   |
| Ubuntu                              | 14.04, 16.04, 18.04, 18.10             |
| Alpine Linux                        | 3.6, 3.7, 3.8                          |
| Amazon Linux                        | 2                                      |
| FreeBSD                             | 10.4, 11.2, 12.0                       |

## Development

To contribute bug patches or new features, you can use the github Pull Request
model. It is assumed that code and documentation are contributed under
the Apache License 2.0.

More info:
* [How to Contribute](http://opennebula.org/addons/contribute/)
* Support: [OpenNebula user forum](https://forum.opennebula.org/c/support)
* Development: [OpenNebula developers forum](https://forum.opennebula.org/c/development)
* Issues Tracking: Github issues (https://github.com/OpenNebula/addon-context-linux/issues)

### Repository structure

All code is located under `src/` and structure follows the installation
directory structure. Files for different environments/targets are picked
by the tag, tags are part of the filename separated from the installation
name by 2 hashes (`##`). Tags are dot-separated.

Examples:

* `script` - non-tagged file for all targets
* `script##systemd` - file tagged with **systemd**
* `script##systemd.rpm` - file tagged with **systemd** and **rpm**

### Contextualization scripts

Contextualization scripts, which are executed on every boot and during
the reconfiguration, are located in `src/etc/one-context.d/`. Scripts are
divided into following 2 parts:

* local - pre-networking, prefixed with `loc-`
* post-networking, prefixed with `net-`

All other scripts, which are not prefixed with `loc-` or `net-`, are
executed as a first during the post-networking contextualization stage.

## Build own package

Package contains following parts:

* main control scripts (`/usr/sbin/one-context*`)
* contextualization scripts (`/etc/one-context.d/*`)
* init scripts to start the contextualization
* OneGate scripts (`/usr/bin/one-gate*`)
* udev rules to trigger reconfiguration on NIC hotplug

Other actions include:

* delete persistent cd and net rules from /etc/udev/rules.d
* delete network configuration files

### Requirements

  * Ruby >= 1.8.7
  * gem fpm >= 1.8.1
  * dpkg utils for deb package creation
  * rpm utils for rpm package creation

On Ubuntu/Debian you can install the package `rpm` and you will be able
to generate both rpm and deb packages.

### Steps

The script `generate.sh` is able to create both **deb** and **rpm** packages
and can be configured to include more files in the package or change some of
its parameters. Package type and content are configured by the env. variable
`TARGET`, the corresponding target must be defined in `target.sh`. Target
describes the package format, name, dependencies, and files. Files are
selected by the tags. Set of required tags is defined for the target
(in `targets.sh`), each file has a list of corresponding tags right in its
filename (divided by the regular name by 2 hashes `##`, dot-separated).

On start it creates a temporary directory and copies there:

  * All files tagged with no, some (but only from TARGET set) or all tags.
  * Any file or directory from the arguments.

The default parameters to create a package are as follows:

```
VERSION=1.0.1
RELEASE=1
MAINTAINER="OpenNebula Systems <support@opennebula.systems>"
LICENSE="Apache 2.0"
VENDOR="OpenNebula Systems"
DESCRIPTION="
This package prepares a VM image for OpenNebula:
  * Disables udev net and cd persistent rules
  * Deletes udev net and cd persistent rules
  * Unconfigures the network
  * Adds OpenNebula contextualization scripts to startup

To get support use the OpenNebula mailing list:
  http://OpenNebula.org
"
URL=http://opennebula.org
```

A target contains following parameters, e.g. **el7** target:

```
NAME=one-context
RELSUFFIX=.el7
TYPE=rpm
TAGS="rpm systemd one"
DEPENDS="util-linux bind-utils cloud-utils-growpart ruby rubygem-json"
REPLACES="cloud-init"
POSTIN=postinstall.one
PREUN=preuninstall.one
```

You can change any parameter setting an environment variable with the same name.
For example, to generate an **el7 rpm** package with a different package name:

```
$ TARGET=el7 NAME=my-one-context ./generate.sh
```

You can also include new files. This is handy to include new scripts executed
to contextualize an image. For example, we can have a script that installs
a user ssh key. We will create the file hierarchy that will go inside
the package in a directory:

```
$ mkdir -p ssh/etc/one-context.d
$ cp <our-ssh-script> ssh/etc/one-context.d/loc-01-ssh-key
$ TARGET=el7 ./generate.sh ssh/etc
```

NOTE: The generator must be executed from the same directory it resides.

### Build package for FreeBSD

Currently, `generate.sh` is not working on FreeBSD and you will have to use Linux distribution to build one-context package for FreeBSD. To generate FreeBSD's package, run:
```
TARGET=freebsd ./generate.sh
```
Above command should generate `one-context-*.txz` package, which you need to copy to the FreeBSD VM. After that, you need to install one-context dependencies and one-context itself:
```
pkg install -y curl bash sudo base64 ruby open-vm-tools-nox11
pkg install -y one-context-[0-9]*.txz
```

## Authors

* Leader: Javier Fontan (jfontan@opennebula.org)

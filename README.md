# OpenNebula Linux VM Contextualization

## Description

This addon provides contextualization packages for the Linux (and, other
Unix-like) guest virtual machines running in the OpenNebula cloud. Based
on the provided contextualization parameters, the packages prepare the
networking in the running guest virt. machine, configure SSH keys, set
passwords, run custom start scripts, and many others.

## Download

Latest versions can be downloaded from the
[release page](https://github.com/OpenNebula/addon-context-linux/releases).
Check the supported OpenNebula versions for each release.

## Install

Documentation on packages installation and guest contextualization can
be found in the latest stable
[OpenNebula Operation Guide](http://docs.opennebula.org/stable/operation/vm_setup/context_overview.html).
For beta releases, refer to the latest
[development documentation](http://docs.opennebula.org/devel/operation/vm_setup/context_overview.html).

## Tested platforms

List of tested platforms only:

| Platform                        | Versions                               |
|---------------------------------|----------------------------------------|
| ALT Linux                       | P9, Sisyphus                           |
| Amazon Linux                    | 2                                      |
| CentOS                          | 6, 7, 8, 8 Stream                      |
| Red Hat Enterprise Linux        | 7, 8                                   |
| Fedora                          | 31, 32, 33                             |
| openSUSE                        | 15, Tumbleweed                         |
| Debian                          | 8, 9, 10                               |
| Devuan                          | 2                                      |
| Ubuntu                          | 14.04, 16.04, 18.04, 20.04, 20.10      |
| Alpine Linux                    | 3.10, 3.11, 3.12                       |
| FreeBSD                         | 11, 12                                 |

(the packages might work on other versions or flavours, but those aren't tested)

## Build own package

Packages for each release for supported guests are available in the
[release page](https://github.com/OpenNebula/addon-context-linux/releases).
Also, any version can be built by the scripts provided in this repository.

### Requirements

* **Linux host**
* **Ruby** >= 1.9
* gem **fpm** >= 1.10.0
* **dpkg utils** for deb package creation
* **rpm utils** for rpm package creation

### Steps

The script `generate.sh` is able to create all package types and can be
configured to include more files in the package or change some of
its parameters. Package type and content are configured by the env. variable
`TARGET`, the corresponding target must be defined in `target.sh`. Target
describes the package format, name, dependencies, and files. Files are
selected by the tags. Set of required tags is defined for the target
(in `targets.sh`), each file has a list of corresponding tags right in its
filename (divided by the regular name by 2 hashes `##`, dot-separated).

Package name or version can be overridden by env. variables `NAME` and `VERSION`.

Examples:

```
$ TARGET=deb ./generate.sh
$ TARGET=el7 NAME=my-one-context ./generate.sh
$ TARGET=alpine ./generate.sh
$ TARGET=freebsd VERSION=5.7.85 ./generate.sh
```

NOTE: The generator must be executed from the same directory it resides.

Check `generate.sh` for general package metadata and `targets.sh` for the list
of targets and their metadata. Most of the parameters can be overriden by
the appropriate environment variable.

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

## License

Copyright 2002-2021, OpenNebula Project, OpenNebula Systems (formerly C12G Labs)

Licensed under the Apache License, Version 2.0 (the "License"); you may
not use this file except in compliance with the License. You may obtain
a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

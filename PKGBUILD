# Maintainer Harvard University FAS Research Computing <rchelp.fas.harvard.edu>

pkgname=one-context
pkgver=4.14.1
pkgrel=1
pkgdesc='OpenNebula Contextualisation'
arch=('any')
url='https://github.com/OpenNebula/addon-context-linux/releases'
license=('Apache')
depends=('mkinitcpio-growrootfs')
source=("")
install=one-context.install
md5sums=('')

package() {
    cd ${srcdir}
    TARGET=arch OUT=${pkgdir} ./generate.sh
    cp -rT ${pkgdir}/usr/sbin ${pkgdir}/usr/bin
    rm -rf ${pkgdir}/usr/sbin
}

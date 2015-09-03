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
    cp -rT ${srcdir}/addon-context-linux-${pkgver}/base_arch ${pkgdir}
    cp -rT ${srcdir}/addon-context-linux-${pkgver}/base ${pkgdir}
    cp -rT ${pkgdir}/usr/sbin ${pkgdir}/usr/bin
    rm -rf ${pkgdir}/usr/sbin
}
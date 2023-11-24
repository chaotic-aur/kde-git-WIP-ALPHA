# Maintainer: Antonio Rojas <arojas@archlinux.org>

pkgname=bluez-qt
pkgver=5.240.0.20231014
pkgrel=1
pkgdesc='Qt wrapper for Bluez 5 DBus API'
arch=(x86_64)
url='https://community.kde.org/Frameworks'
license=(GPL2)
depends=(bluez
         gcc-libs
         glibc
         qt6-base)
makedepends=(doxygen
             extra-cmake-modules
             qt6-declarative
             qt6-doc
             qt6-tools)
optdepends=('qt6-declarative: QML bindings')
groups=(kf6)
#source=(https://download.kde.org/stable/frameworks/${pkgver%.*}/$pkgname-$pkgver.tar.xz{,.sig})
makedepends+=(git)
_commit=98bf8d0abb449c11357a9d0e045b6557b0daaba4
source=(git+https://invent.kde.org/frameworks/$pkgname#commit=$_commit)
sha256sums=('SKIP')
validpgpkeys=(53E6B47B45CEA3E0D5B7457758D0EE648A48B3BB) # David Faure <faure@kde.org>

build() {
  cmake -B build -S $pkgname \
    -DUDEV_RULES_INSTALL_DIR=/usr/lib/udev/rules.d \
    -DBUILD_TESTING=OFF \
    -DBUILD_QCH=ON
  cmake --build build
}

package() {
  DESTDIR="$pkgdir" cmake --install build
}

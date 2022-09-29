#!/bin/bash -e
# Creates a systemd-nspawn container with Ubuntu

CODENAME=${CODENAME:-focal}
RELEASE="20.04.1"
ARCH="arm64"

if [ $UID -ne 0 ]; then
	echo "run this script as root" >&2
	exit 1
fi

if [ -z "$1" ]; then
	echo "Usage: $0 <destination>" >&2
	exit 0
fi

dest="$1"
rootfs=$(mktemp)
wget "https://cdimage.ubuntu.com/cdimage/ubuntu-base/releases/${CODENAME}/release/ubuntu-base-${RELEASE}-base-${ARCH}.tar.gz" -O $rootfs
#wget "http://cloud-images.ubuntu.com/${CODENAME}/current/${CODENAME}-server-cloudimg-arm64-root.tar.xz" -O $rootfs
trap 'rm $rootfs' EXIT

mkdir -p "$dest"
tar -xaf $rootfs -C "$dest"

sed '/^root:/ s|\*||' -i "$dest/etc/shadow" # passwordless login
rm "$dest/etc/resolv.conf" # systemd configures this
# https://github.com/systemd/systemd/issues/852
[ -f "$dest/etc/securetty" ] && \
	printf 'pts/%d\n' $(seq 0 10) >>"$dest/etc/securetty"
>"$dest/etc/fstab"
cp /usr/bin/qemu-aarch64-static $dest/usr/bin/
cp ~/jingos-build/apt/*.list $dest/etc/apt/sources.list.d/
cp ~/jingos-build/apt/*.pref $dest/etc/apt/preferences.d/
systemd-nspawn -q -D "$dest" /usr/bin/apt-get update
systemd-nspawn -q -D "$dest" /usr/bin/apt-get -y upgrade
systemd-nspawn -q -D "$dest" /usr/bin/apt-get install -y ubuntu-minimal vim openssh-server



echo ""
echo "Ubuntu $CODENAME container was created successfully"

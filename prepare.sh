#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause

set -ex

echo "Install dependencies"

sudo add-apt-repository ppa:v-launchpad-jochen-sprickerhof-de/sbuild
sudo apt update
sudo apt install -y sbuild mmdebstrap distro-info debian-archive-keyring ccache vcstool python3-rosdep2 catkin python3-bloom

echo "Setup build environment"

mkdir -p ~/.cache/sbuild
mmdebstrap --variant=buildd --include=apt,ccache \
  --customize-hook='chroot "$1" update-ccache-symlinks' \
  --components=main,universe "$DEB_DISTRO" "$HOME/.cache/sbuild/$DEB_DISTRO-amd64.tar"

ccache --zero-stats --max-size=10.0G

# allow ccache access from sbuild
chmod a+rwX ~
chmod -R a+rwX ~/.cache/ccache

cat << "EOF" > ~/.sbuildrc
$build_environment = { 'CCACHE_DIR' => '/build/ccache' };
$path = '/usr/lib/ccache:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games';
$build_path = "/build/package/";
$dsc_dir = "package";
$unshare_bind_mounts = [ { directory => '/home/runner/.cache/ccache', mountpoint => '/build/ccache' } ];
EOF

echo "Checkout workspace"

mkdir src
vcs import src < "$REPOS_FILE"

#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause

set -ex

# make output directory
mkdir /home/runner/apt_repo

echo "Add unreleased packages to rosdep"

echo "{distributions: {$ROS_DISTRO: {distribution: [https://raw.githubusercontent.com/ros/rosdistro/master/$ROS_DISTRO/distribution.yaml, local.yaml]}}, type: index, version: 4}" > index-v4.yaml
printf "release_platforms: {ubuntu: [%s]}\ntype: distribution\nversion: 2\nrepositories:\n" "$DEB_DISTRO" > local.yaml
for PKG in $(colcon list -n); do
  echo "  $PKG: {release: {tags: {release: None}, url: None}}" >> local.yaml
done

sudo rosdep init
ROSDISTRO_INDEX_URL="file://$(pwd)/index-v4.yaml" rosdep update

echo "Run sbuild"

# Don't build tests
export DEB_BUILD_OPTIONS=nocheck

TOTAL="$(colcon list | wc -l)"
COUNT=1

for PKG_PATH in $(colcon list -tp); do
  [ "$TOTAL" -ne 1 ] && echo "::group::Building $COUNT/$TOTAL: $PKG_PATH"
  (
  cd "$PKG_PATH"
  bloom-generate rosdebian --os-name=ubuntu --os-version="$DEB_DISTRO" --ros-distro="$ROS_DISTRO"

  # Set the version
  sed -i "1 s/([^)]*)/($(git describe --tag)-$(date +%Y.%m.%d.%H.%M))/" debian/changelog

  # https://github.com/ros-infrastructure/bloom/pull/643
  echo 11 > debian/compat

  # dpkg-source-opts: no need for upstream.tar.gz
  sbuild --chroot-mode=unshare --no-clean-source --no-run-lintian \
    --dpkg-source-opts="-Zgzip -z1 --format=1.0 -sn" \
    --build-dir=/home/runner/apt_repo --extra-package=/home/runner/apt_repo \
    --extra-repository="deb http://packages.ros.org/ros2/ubuntu $DEB_DISTRO main" \
    --extra-repository-key=/usr/share/keyrings/ros-archive-keyring.gpg
  )
  sudo chown -R runner:docker ~/.cache/ccache/
  chmod -R a+rwX ~/.cache/ccache
  ccache -sv
  COUNT=$((COUNT+1))
  test "$TOTAL" -ne 1 && echo "::endgroup::"
  true
done

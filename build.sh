#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause

set -ex

while getopts ch OPTCHAR; do
  case "$OPTCHAR" in
    c)
      CONTINUE_PACKAGE_GENERATION=1
      ;;
    h)
      echo "usage: $0 [-c]"
      echo "  -c To continue at the last package and skip those already built."
      exit
      ;;
    *)
      echo "Error parsing arguments"
      exit 1
      ;;
  esac
done
shift "$((OPTIND - 1))"

if debian-distro-info --all | grep -q "$DEB_DISTRO"; then
  DISTRIBUTION=debian
elif ubuntu-distro-info --all | grep -q "$DEB_DISTRO"; then
  DISTRIBUTION=ubuntu
else
  echo "Unknown DEB_DISTRO: $DEB_DISTRO"
  exit 1
fi

case $ROS_DISTRO in
  debian)
    ;;
  boxturtle|cturtle|diamondback|electric|fuerte|groovy|hydro|indigo|jade|kinetic|lunar)
    echo "Unsupported ROS 1 version: $ROS_DISTRO"
    exit 1
    ;;
  melodic|noetic)
    BLOOM=ros
    ROS_DEB="$ROS_DISTRO-"
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /home/runner/ros-archive-keyring.gpg
    set -- --extra-repository="deb http://packages.ros.org/ros/ubuntu $DEB_DISTRO main" --extra-repository-key=/home/runner/ros-archive-keyring.gpg "$@"
    ;;
  *)
    # assume ROS 2 so we don't have to list versions
    BLOOM=ros
    ROS_DEB="$ROS_DISTRO-"
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /home/runner/ros-archive-keyring.gpg
    set -- --extra-repository="deb http://packages.ros.org/ros2/ubuntu $DEB_DISTRO main" --extra-repository-key=/home/runner/ros-archive-keyring.gpg "$@"
    ;;
esac

# make output directory
mkdir -p /home/runner/apt_repo

echo "Add unreleased packages to rosdep"

for PKG in $(catkin_topological_order --only-names); do
  printf "%s:\n  %s:\n  - %s\n" "$PKG" "$DISTRIBUTION" "ros-$ROS_DEB$(printf '%s' "$PKG" | tr '_' '-')" >> /home/runner/apt_repo/local.yaml
done
echo "yaml file:///home/runner/apt_repo/local.yaml $ROS_DISTRO" | sudo tee /etc/ros/rosdep/sources.list.d/1-local.list
printf "%s" "$ROSDEP_SOURCE" | sudo tee /etc/ros/rosdep/sources.list.d/2-remote.list

rosdep update

echo "Run sbuild"

# Don't build tests
export DEB_BUILD_OPTIONS=nocheck

TOTAL="$(catkin_topological_order --only-names | wc -l)"
COUNT=1

# TODO: use colcon list -tp in future
for PKG_PATH in $(catkin_topological_order --only-folders); do
  echo "::group::Building $COUNT/$TOTAL: $PKG_PATH"
  test -f "$PKG_PATH/CATKIN_IGNORE" && echo "Skipped" && continue
  test -f "$PKG_PATH/COLCON_IGNORE" && echo "Skipped" && continue
  (
  cd "$PKG_PATH"
  GENERATED_DEBIAN_PACKAGE="ros-${ROS_DEB}$(catkin_topological_order --only-names | tr '_' '-')"
  if [ -n "$CONTINUE_PACKAGE_GENERATION" ] && ls "/home/runner/apt_repo/${GENERATED_DEBIAN_PACKAGE}_"*.deb >/dev/null 2>&1; then
    echo " Skipping already generated package: ${GENERATED_DEBIAN_PACKAGE}"
    exit
  fi

  bloom-generate "${BLOOM}debian" --os-name="$DISTRIBUTION" --os-version="$DEB_DISTRO" --ros-distro="$ROS_DISTRO"

  # Set the version based on the checked out tag that contain at least on digit
  # strip any leading non digits as they are not part of the version number
  sed -i "1 s@([^)]*)@($( (git describe --tag  --match "*[0-9]*" 2>/dev/null || echo 0) | sed 's@^[^0-9]*@@')-$(date +%Y.%m.%d.%H.%M))@" debian/changelog

  # https://github.com/ros-infrastructure/bloom/pull/643
  echo 11 > debian/compat

  # dpkg-source-opts: no need for upstream.tar.gz
  sbuild --chroot-mode=unshare --no-clean-source --no-run-lintian \
    --dpkg-source-opts="-Zgzip -z1 --format=1.0 -sn" --build-dir=/home/runner/apt_repo \
    --extra-package=/home/runner/apt_repo "$@"
  )
  COUNT=$((COUNT+1))
  echo "::endgroup::"
done

ccache -sv

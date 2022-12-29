#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause

set -ex

vcs export src --exact-with-tags > /home/runner/apt_repo/upstream.repos
cd /home/runner/apt_repo
apt-ftparchive packages . > Packages
apt-ftparchive release . > Release
echo "deb [trusted=yes] https://raw.githubusercontent.com/$GITHUB_REPOSITORY/$DEB_DISTRO-$ROS_DISTRO/ ./" > README.md

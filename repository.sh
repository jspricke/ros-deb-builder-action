#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause

set -ex

vcs export src --exact-with-tags > /home/runner/apt_repo/sources.repos

cd /home/runner/apt_repo
apt-ftparchive packages . > Packages
apt-ftparchive release . > Release

REPOSITORY="$(printf "%s" "$GITHUB_REPOSITORY" | tr / _)"
echo '```bash' > README.md
echo "echo \"deb [trusted=yes] https://raw.githubusercontent.com/$GITHUB_REPOSITORY/$DEB_DISTRO-$ROS_DISTRO/ ./\" | sudo tee /etc/apt/sources.list.d/$REPOSITORY.list" >> README.md
echo "echo \"yaml https://raw.githubusercontent.com/$GITHUB_REPOSITORY/$DEB_DISTRO-$ROS_DISTRO/local.yaml $ROS_DISTRO\" | sudo tee /etc/ros/rosdep/sources.list.d/1-$REPOSITORY.list" >> README.md
echo '```' >> README.md

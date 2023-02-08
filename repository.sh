#!/bin/sh
# SPDX-License-Identifier: BSD-3-Clause

set -ex

vcs export src --exact-with-tags > apt_repo/sources.repos

cd apt_repo
apt-ftparchive packages . > Packages
apt-ftparchive release . > Release

REPOSITORY="$(printf "%s" "$GITHUB_REPOSITORY" | tr / _)"
BRANCH="$DEB_DISTRO-$ROS_DISTRO"
echo '```bash' > README.md
echo "echo \"deb [trusted=yes] https://raw.githubusercontent.com/$GITHUB_REPOSITORY/$BRANCH/ ./\" | sudo tee /etc/apt/sources.list.d/$REPOSITORY.list" >> README.md
echo "echo \"yaml https://raw.githubusercontent.com/$GITHUB_REPOSITORY/$BRANCH/local.yaml $ROS_DISTRO\" | sudo tee /etc/ros/rosdep/sources.list.d/1-$REPOSITORY.list" >> README.md
echo '```' >> README.md

test -z "$GITHUB_TOKEN" && exit

git init -b "$BRANCH"
git remote add origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
if [ "$SQUASH_HISTORY" != "true" ]; then
  git fetch origin "$BRANCH" && git reset --soft FETCH_HEAD || true
fi
git add .
git -c user.name=Github -c user.email=none commit --message="Generated from $(git -C .. rev-parse --short HEAD)"
git push --force origin "$BRANCH"

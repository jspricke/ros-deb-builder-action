# ROS Debian package builder action

Convert ROS packages to Debian packages.

## Inputs

## `ROS_DISTRO`

**Required** The ROS distribution codename to compile for.

## `DEB_DISTRO`

**Required** The Debian/Ubuntu distribution codename to compile for.

## `REPOS_FILE`

Repos file with list of repositories to package.
Defaults to sources.repos.

## `SBUILD_CONF`

Additional sbuild.conf lines.
For example EXTRA_REPOSITORIES, or VERBOSE.
See man sbuild.conf.

## `ROSDEP_SOURCE`

Additional rosdep sources.

## `GITHUB_TOKEN`

Set to `${{ secrets.GITHUB_TOKEN }}` to deploy to a `DEB_DISTRO-ROS_DISTRO` branch in the same repo.

## ``SQUASH_HISTORY``

If set to true, all previous commits on the target branch will be discarded.
For example, if you are deploying a static site with lots of binary artifacts, this can help prevent the repository from becoming overly bloated

## Example usage

```
uses: jspricke/ros-deb-builder-action@main
with:
  ROS_DISTRO: rolling
  DEB_DISTRO: jammy
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Run manually

You can run this action locally on Ubuntu 22.04 or Debian bookworm and newer system.

Run `./prepare -d <deb_distro>` once to set up the system and/or adapt to your needs.
It will create a `~/.cache/sbuild` with sufficient rights for the sbuild process, a `~/.sbuildrc` and a `./src` with the checked out repos.

Run `./build -r <ros_distro> -d <deb_distro>` in a ROS workspace (or the current directory with `./src`) to generate the packages into the `apt_repo` folder.
You can run `./build -c` to skip already built packages.
The `rosdep` cache is updated twice within the script to include the packages in the local repo, but reverted to the original cache afterwards.

Run `./repository -r <ros_distro> -d <deb_distro>` to create an apt repository.
You can directly use it on your local machine by adapting the path from the generated `README.md`.

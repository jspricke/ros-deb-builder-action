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

## `SKIP_ROS_REPOSITORY`

Don't add packages.ros.org as an apt repository.
This allows to build against snapshots.ros.org, for example.

## `SKIP_PACKAGES`

Whitespace separated list of ROS package names not to be build.
Note that you need to list downstream dependencies of skipped packages in addition.

## `GITHUB_TOKEN`

Set to `${{ secrets.GITHUB_TOKEN }}` to deploy to a `DEB_DISTRO-ROS_DISTRO` branch in the same repo.

## ``SQUASH_HISTORY``

If set to true, all previous commits on the target branch will be discarded.
For example, if you are deploying a static site with lots of binary artifacts, this can help prevent the repository from becoming overly bloated

## ``PACKAGES_BRANCH``
If set, this branch will be used to push the packages instead of `DEB_DISTRO-ROS_DISTRO`.

## Example usage

```
name: builder

on:
  workflow_dispatch:
  push:

jobs:
  build_testing:
    runs-on: ubuntu-22.04
    steps:
      - uses: jspricke/ros-deb-builder-action@main
        with:
          ROS_DISTRO: rolling
          DEB_DISTRO: jammy
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Run manually

You can run this action locally on Ubuntu 22.04 or Debian bookworm and newer system.

Run `./prepare -d <deb_distro>` once to set up the system and/or adapt to your needs.
It will create a `~/.cache/ccache` with sufficient rights for the sbuild process, a `~/.sbuildrc`, a `~/.cache/sbuild` and optionally a `./src` with the checked out repos.

Run `./build -r <ros_distro> -d <deb_distro>` in a ROS workspace (or the current directory with `./src`) to generate the packages into the `apt_repo` folder.
You can run `./build -c` to skip already built packages.

Run `./repository -r <ros_distro> -d <deb_distro>` to create an apt repository.
You can directly use it on your local machine by adapting the path from the generated `README.md`.

## FAQ

### The action fails with:
```
remote: Permission to <REPO_NAME> denied to github-actions[bot].
fatal: unable to access '<REPO_URL>': The requested URL returned error: 403
```

Make sure the `GITHUB_TOKEN` has permission to write to the git repository.
In the Github webinterface of the project got to Settings, Actions, General.
At the bottom there is "Workflow permissions", make sure "Read and write permissions" is selected.

### The apt repository is missing some packages

Github has a hard limit of 100MB per file, so the Action deletes bigger files before pushing.
You could omit the `GITHUB_TOKEN` and add your own deploy method as a final step.

### How to use a private repo as an apt source

Create a Github personal access token with repo scope and do:
```
echo -e "machine raw.githubusercontent.com\nlogin <TOKEN>" | sudo tee /etc/apt/auth.conf.d/github.conf

```

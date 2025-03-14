# ROS Debian package builder action

Convert ROS packages to Debian packages.

## Inputs

## `ROS_DISTRO`

**Required** The ROS distribution codename to compile for.

## `DEB_DISTRO`

**Required** The Debian/Ubuntu distribution codename to compile for.

## `DEB_ARCH`

The architecture (`amd64`, `arm64`, ...) to compile for.

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

## `SKIP_CHECKOUT`

Do not check out the repository. This allows you to manually construct a repos file or workspace.

## `GITHUB_TOKEN`

Set to `${{ secrets.GITHUB_TOKEN }}` to deploy to a `$DEB_DISTRO-$ROS_DISTRO-$DEB_ARCH` branch in the same repo.

## ``SQUASH_HISTORY``

If set to true, all previous commits on the target branch will be discarded.
For example, if you are deploying a static site with lots of binary artifacts, this can help prevent the repository from becoming overly bloated

## ``PACKAGES_BRANCH``
If set, this branch will be used to push the packages instead of `$DEB_DISTRO-$ROS_DISTRO-$DEB_ARCH`.

## ``GIT_LFS``

If set to true, Git Large File Storage will be used to store the generated binaries.

## Example usage

```
name: builder

on:
  workflow_dispatch:
  push:

jobs:
  build_testing:
    runs-on: ubuntu-24.04
    steps:
      - uses: jspricke/ros-deb-builder-action@main
        with:
          ROS_DISTRO: rolling
          DEB_DISTRO: jammy
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Run manually

You can run this action locally on Ubuntu 22.04 or Debian bookworm and newer system.

Run `./prepare -d <deb_distro> -a <arch>` once to set up the system and/or adapt to your needs.
It will create a `~/.cache/ccache` with sufficient rights for the sbuild process, a `~/.sbuildrc`, a `~/.cache/sbuild` and optionally a `./src` with the checked out repos.

Run `./build -r <ros_distro> -d <deb_distro> -a <arch>` in a ROS workspace (or the current directory with `./src`) to generate the packages into the `apt_repo` folder.
You can run `./build -c` to skip already built packages.

Run `./repository -r <ros_distro> -d <deb_distro> -a <arch>` to create an apt repository.
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

### The build needs network access

sbuild denies network access during the build by default as per Debian policy 4.9.
To allow network access use in the action:
```
SBUILD_CONF: "$enable_network = 1;"
```

### How to use a private repo as an apt source

Create a Github personal access token with repo scope and do:
```
echo -e "machine raw.githubusercontent.com\nlogin <TOKEN>" | sudo tee /etc/apt/auth.conf.d/github.conf

```

### How to use a private repo as a rosdep source

Rosdep doesn't support authentication with private repos, so as a workaround you'll have to manually download the `local.yaml` file and reference that file in rosdep sources instead of the github url.

```bash
# Download the local.yaml file to a path of your choice
curl -H "Authorization: token <your_PAT_token>" https://raw.githubusercontent.com/<user>/<repo_name>/<branch>/local.yaml | sudo tee /etc/ros/rosdep/mappings-<repo_name>.yaml

# Add the file to rosdep sources instead of the github url
echo "yaml file:///etc/ros/rosdep/mappings-<repo_name>.yaml <ros_distro>" | sudo tee /etc/ros/rosdep/sources.list.d/1-<repo_name>.list
```

Now the typical `rosdep update` and `rosdep install` commands should work as expected, but remember to redownload the `local.yaml` when there are changes to the packages.

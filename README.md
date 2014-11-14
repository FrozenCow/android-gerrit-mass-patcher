# Android Gerrit Mass Patcher

This is used to apply patches of DriveDroid to all devices of a number of roms that use Gerrit to review patches.

It goes through the following steps:

* Read the available roms from roms/.
* For each rom run gerrit\_mass\_patch.sh
* Retrieve all kernel projects from Gerrit.
* For each kernel project check whether the specified branch exists.
* Fetch the sources of said branch.
* Skip when the patch was already applied to branch (by looking for changeid in said branch).
* Cherry-pick the patch onto said branch.
* Create new branch for patched result.
* Push the change to Gerrit under specified topic.

This isn't set up so that others can easily use it, but mostly for myself to make sure new devices will get the proper patches.

## Usage

```sh
$ cd ~/projects/linux
$ ~/projects/android-gerrit-mass-patcher/mass_patch_all.sh
```

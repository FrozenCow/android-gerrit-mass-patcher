#!/bin/bash

username="FrozenCow"
cherries=(680ff7911e5d0701e81cd0d0d5235b300ce44a86 92211c0ca1ba14dc05795f3add6c88da9f656608)
patchname="gadget_cdrom"
changeid="Idf83c74815b1ad370428ab9d3e5503d5f7bcd3b6"
topic="DriveDroid"

if [ -n "$(git status --porcelain)" ]; then
    echo "There are uncommitted changes in the repository: cancel"
    exit 1
fi

containsElement () {
	local e
	for e in "${@:2}"; do [[ "$e" == "$1" ]] && return 0; done
	return 1
}

# Retrieve all kernel projects
projects=($(ssh -p 29418 ${username}@${gerrit} gerrit ls-projects | grep kernel_))

# Do not handle projects that are on the blacklist
blacklist_projects=()
for project in ${blacklist_projects[@]}; do
	projects=("${projects[@]/${project}}")
done

# Do not handle projects that already have $changeid submitted
changed_projects=($(curl -L -s "http://${gerrit}/changes/?q=change:${changeid}" | tail -n+2 | jq --raw-output '.[].project'))
#changed_projects=(CyanogenMod/android_kernel_google_msm CyanogenMod/android_kernel_sony_msm8930 CyanogenMod/android_kernel_samsung_msm8660-common CyanogenMod/android_kernel_samsung_mondrianwifi CyanogenMod/android_kernel_motorola_msm8960dt-common CyanogenMod/android_kernel_motorola_msm8960-common CyanogenMod/android_kernel_lge_v500 CyanogenMod/android_kernel_lge_msm8974 CyanogenMod/android_kernel_htc_enrc2b CyanogenMod/android_kernel_samsung_hlte CyanogenMod/android_kernel_motorola_msm8226 CyanogenMod/android_kernel_xiaomi_aries CyanogenMod/android_kernel_sony_msm8974pro CyanogenMod/android_kernel_sony_msm8974 CyanogenMod/android_kernel_sony_apq8064 CyanogenMod/android_kernel_oppo_find5 CyanogenMod/android_kernel_oneplus_msm8974 CyanogenMod/android_kernel_oppo_n1 CyanogenMod/android_kernel_oppo_find5 CyanogenMod/android_kernel_sony_msm8x60 CyanogenMod/android_kernel_sony_msm8960t CyanogenMod/android_kernel_htc_msm8974 CyanogenMod/android_kernel_lge_hammerhead CyanogenMod/lge-kernel-mako CyanogenMod/android_kernel_htc_endeavoru CyanogenMod/android_kernel_htc_m7 CyanogenMod/android_kernel_htc_msm8960 CyanogenMod/android_kernel_samsung_crespo CyanogenMod/android_kernel_samsung_tuna CyanogenMod/android_kernel_sony_apq8064 CyanogenMod/android_kernel_sony_msm8x60 CyanogenMod/android_kernel_samsung_d2)
for project in ${changed_projects[@]}; do
    projects=("${projects[@]/${project}}")
done

for project in ${projects[@]}
do
    # Make sure no '/' is used in the project name (ie CyanogenMod/android_kernel_lge_hammerhead).
    # Also make sure the name is prefixed with $projectprefix if it didn't already have the prefix.
    projectname="${project//\//_}"
    projectname="${projectname#$projectprefix}"
    projectname="${projectprefix}${projectname}"

    echo "$project -> $projectname"
    git remote add ${projectname} http://${gerrit}/${project} 2> /dev/null || true

    if ! git fetch ${projectname}; then
        echo "Failed to fetch ${projectname}: cancel"
        continue
    fi

    if ! git show-ref --quiet remotes/${projectname}/${branch} > /dev/null 2>&1; then
        echo "Branch ${branch} not found for ${project}: cancel"
        continue
    fi

    if [ "$(git --no-pager log --quiet --grep="Change-Id: ${changeid}" --oneline ${projectname}/${branch})" != "" ]; then
        echo "Already patched ${projectname}/${branch}: cancel"
        continue
    fi

    git branch -D ${projectname}_${branch}_${patchname} > /dev/null 2>&1 || true
    git branch ${projectname}_${branch}_${patchname} ${projectname}/${branch} > /dev/null 2>&1 || true

    if ! git checkout ${projectname}_${branch}_${patchname} > /dev/null 2>&1; then
        echo "Failed to checkout to branch ${projectname}_${branch}_${patchname}: cancel"
        continue
    fi

    cherry_applied=0
    for cherry in ${cherries[@]}; do
        if ! git cherry-pick "${cherry}" > /dev/null 2> /dev/null; then
            echo "Failed to apply cherry ${cherry} on ${projectname}_${branch}_${patchname}: continue"
            git cherry-pick --abort
            continue
        fi
        cherry_applied=1
    done

    if [ "$cherry_applied" = "0" ]; then
        echo "Failed to cherry-pick on ${projectname}_${branch}_${patchname}: cancel"
    fi

    echo "Success ${projectname}_${branch}_${patchname}"
    git push ssh://${username}@${gerrit}:29418/${project} HEAD:refs/for/${branch}/${topic} || true
done

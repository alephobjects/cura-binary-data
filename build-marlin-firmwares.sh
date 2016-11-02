#!/bin/bash

CLEAN=0
BUILD_TAG_PREFIX='TAZ_6'
BUILD_TAGS=''
BUILD_BRANCH_PREFIX=''
BUILD_BRANCHES='Gladiola'
GIT_URL='https://code.alephobjects.com/diffusion/MARLIN/marlin.git'

BUILD_DIR='build-marlin'
MIN_AVR_GCC_VERSION="4.8.1"


# Compare version strings.
# Source: https://stackoverflow.com/questions/4023830/how-compare-two-strings-in-dot-separated-version-format-in-bash
vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}

# Check for avr-g++ and verify its version matches our min version
#
HAVE_AVR_GCC=$(which avr-g++ >& /dev/null && echo 1 || echo 0)
if [ "${HAVE_AVR_GCC}" == "0" ] ; then
    echo "Error: Cannot find avr-gcc/avr-g++"
    echo "Make sure you install avr-gcc and avr-g++ on your system"
    echo "before continuing."
    exit -1
else
    AVR_GCC_VERSION=$(avr-gcc -v 2>&1 | tail -1 | awk '{print $3}')
    vercomp "$AVR_GCC_VERSION" "$MIN_AVR_GCC_VERSION"
    COMP=$?
    if [ "$COMP" == "2" ] ; then
        echo "Error: Your avr-gcc installation is too old"
        echo "avr-gcc version is : ${AVR_GCC_VERSION}"
        echo "Minimum avr-gcc version is : ${MIN_AVR_GCC_VERSION}"
        echo "Please update your avr-gcc installation before continuing."
        exit -1
    fi
fi

# Clean and clone the Marlin repository
#
if [ "${CLEAN}" == "1" -o ! -d ${BUILD_DIR} ] ; then
    rm -rf ${BUILD_DIR}
    mkdir -p ${BUILD_DIR}
    echo "***** Cloning Marlin from git *****"
    git clone ${GIT_URL} ${BUILD_DIR} >& /dev/null
fi

# Get list of branches and list of tags
#
cd ${BUILD_DIR}
tags=$(git tag -l)
branches=$(git branch -l -r | sed 's#  origin/##g')

# Build marlin, save log and move hex files to current dir
function build_marlin {
    log_name=$1

    make -C Marlin >& build_${log_name}.log
    mv Marlin/*.hex .
}

# Build a tag of marlin
function build_marlin_tag {
    tag=$1

    echo "***** Building tag : ${tag} *****"
    # We need to delete the branch if it exists, otherwise we
    # can fail to checkout in case there are any local changes
    git branch -D ${tag}_ >& /dev/null || true
    # We add a '_' to the branch name otherwise the makefile will 
    # fail due to the 'git rev-parse' to get the machine name will
    # return 'heads/${tag}' to differentiate the branch from the tag
    # and that causes the filename to contain a '/' which breaks the compilation
    git checkout -f ${tag} -B ${tag}_
    build_marlin $tag
    if [ $? == 0 ] ; then
        RESULT="SUCCESS"
    else
        RESULT="FAILED"
    fi
    echo "   === ${RESULT} ==="
    echo ""
}

# Build a branch of marlin
function build_marlin_branch {
    branch="$1"
    origin_branch="origin/${branch}"

    echo "***** Building branch : ${branch} *****"
    git checkout -f ${origin_branch} -B ${branch}
    build_marlin $branch
    if [ $? == 0 ] ; then
        RESULT="SUCCESS"
    else
        RESULT="FAILED"
    fi
    echo "   === ${RESULT} ==="
    echo ""
}

# Build tags
for tag in $tags ; do
    for build_tag in ${BUILD_TAGS} ; do
        if [[ "$tag" == "$build_tag" ]]; then
            build_marlin_tag $tag
        fi
    done
    for build_tag in ${BUILD_TAG_PREFIX} ; do
        if [[ "$tag" == "${build_tag}"* ]]; then
            build_marlin_tag $tag
        fi
    done
done

# Build branches
for branch in $branches ; do
    #echo "Checking branch ${branch}"
    for build_branch in ${BUILD_BRANCHES} ; do
        #echo "Checking ${branch} against build branch ${build_branch}"
        if [[ "$branch" == "$build_branch" ]]; then
            build_marlin_branch $branch
        fi
    done
    for build_branch in ${BUILD_BRANCH_PREFIX} ; do
        #echo "Checking ${branch} against branch prefix ${build_branch}"
        if [[ "$branch" == "${build_branch}"* ]]; then
            build_marlin_branch $branch
        fi
    done
done

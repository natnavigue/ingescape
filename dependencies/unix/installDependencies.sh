#!/usr/bin/env bash

# Constants
#FIXME The OS names and versions could also be constants to have cleaners conditions and avoid =~ operations
ZEROMQ_REPO_BASE_URL_DEBIAN="http://download.opensuse.org/repositories/network:/messaging:/zeromq:/git-stable/Debian"
ZEROMQ_REPO_URL_DEBIAN_9="${ZEROMQ_REPO_BASE_URL_DEBIAN}_9.0/"
ZEROMQ_REPO_URL_DEBIAN_10="${ZEROMQ_REPO_BASE_URL_DEBIAN}_Next/"

# Package file name. GENERATED BY CPACK. DO NOT MODIFY MANUALLY.
LINUX_PACKAGE_FILE_NAME=""
DARWIN_PACKAGE_FILE_NAME=""

# Current OS name. Set by discover_os.
OS=""
# OS version. Set by discover_os.
VER=""
# Current architecture. Set by discover_arch.
ARCH=""

# Checks whether the current user is root or not and make use of 'sudo' if needed.
#FIXME What if the user does not have sudo access rights ?
function _check_sudo {
    if [[ $EUID = 0 ]]
    then
        $1
    else
        sudo $1
    fi
}

# Tries to discover the current Linux flavor and sets the OS and VER variables.
function discover_os {
    if [ -f /etc/os-release ]; then
        # freedesktop.org and systemd
        . /etc/os-release
        OS=$NAME
        # NOTE As of March 1st 2019, there is no VERSION_ID in os-release for buster (testing). The following condition checks that
        if [[ -z ${VERSION_ID+x} ]]
        then
            VER="10"
        else
            VER=$VERSION_ID
        fi
    elif type lsb_release >/dev/null 2>&1; then
        # linuxbase.org
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    elif [ -f /etc/lsb-release ]; then
        # For some versions of Debian/Ubuntu without lsb_release command
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        # Older Debian/Ubuntu/etc.
        OS=Debian
        VER=$(cat /etc/debian_version)
    elif [ -f /etc/SuSe-release ]; then
        # Older SuSE/etc.
        OS=SuSE
        VER=$(cat /etc/SuSe-version)
    elif [ -f /etc/redhat-release ]; then
        # Older Red Hat, CentOS, etc.
        OS=REHL
        VER=$(cat /etc/redhat-version)
    else
        # Fall back to uname, e.g. "Linux <version>", also works for BSD, etc.
        OS=$(uname -s)
        VER=$(uname -r)
    fi
}

# Tries to discover the current machine architecture (x86 or x64)
function discover_arch {
    case $(uname -m) in
    x86_64)
        ARCH=x64  # x64
        ;;
    i*86)
        ARCH=x86  # x86
        ;;
    armv7)
        ARCH=armhf  # ARMv7 (armhf)
        ;;
    *)
        # leave ARCH as-is
        ;;
    esac
}

function install_deps_debian {
    lib_list="libzmq5 czmq zyre"
    if [[ "$VER" =~ "9" ]]
    then
        lib_list="${lib_list} libsodium18"
    elif [[ "$VER" =~ "10" ]]
    then
        lib_list="${lib_list} libsodium23"
    fi

    if [[ "$DEVEL_LIBS" == "YES" ]]
    then
        lib_list="${lib_list} libzmq3-dev libzyre-dev libczmq-dev libsodium-dev"
    fi

    apt install -y $lib_list
}

function install_deps_centos {
    lib_list="libzmq5 czmq zyre libsodium18"

    if [[ "$DEVEL_LIBS" == "YES" ]]
    then
        lib_list="${lib_list} zeromq-devel zyre-devel czmq-devel libsodium-devel"
    fi

    yum install -y ${lib_list}
}

function install_deps_darwin {
    brew install libsodium zeromq czmq zyre
    #FIXME Is there a distinction between 'regular' and 'development' libs for osx ?
}

function install_deps_from_git {
    ( # libsodium
        git clone --depth 1 -b stable https://github.com/jedisct1/libsodium.git
        cd libsodium
        ./autogen.sh && ./configure && make check
        _check_sudo "make install"
    )
    ( # libzmq
        git clone git://github.com/zeromq/libzmq.git
        cd libzmq
        ./autogen.sh
        # do not specify "--with-libsodium" if you prefer to use internal tweetnacl
        # security implementation (recommended for development)
        ./configure
        make check
        _check_sudo "make install"
        _check_sudo ldconfig
    )
    ( # czmq
        git clone git://github.com/zeromq/czmq.git
        cd czmq
        ./autogen.sh && ./configure && make check
        _check_sudo "make install"
        _check_sudo ldconfig
    )
    ( # zyre
        git clone git://github.com/zeromq/zyre.git
        cd zyre
        ./autogen.sh && ./configure && make check
        _check_sudo "make install"
        _check_sudo ldconfig
    )
}

# Installs the ZeroMQ repository for Debian or CentOS based on the values of OS and VER variables.
function setup_repos {
    case $OS in
        *Debian*)
            if grep -Fq "${ZEROMQ_REPO_BASE_URL_DEBIAN}" /etc/apt/sources.list
            then
                echo "ZeroMQ package repository already present in /etc/apt/sources.list"
            else
                case $VER in
                    *10*)
                        ## Debian buster
                        echo "" >> /etc/apt/sources.list
                        echo "# ZeroMQ repository (added by ingescape)" >> /etc/apt/sources.list
                        echo "deb ${ZEROMQ_REPO_URL_DEBIAN_10} ./" >> /etc/apt/sources.list
                        wget ${ZEROMQ_REPO_URL_DEBIAN_10}Release.key -O- | apt-key add
                        ;;

                    *9*)
                        ## Debian stretch
                        echo "" >> /etc/apt/sources.list
                        echo "# ZeroMQ repository (added by ingescape)" >> /etc/apt/sources.list
                        echo "deb ${ZEROMQ_REPO_URL_DEBIAN_9} ./" >> /etc/apt/sources.list
                        wget ${ZEROMQ_REPO_URL_DEBIAN_9}Release.key -O- | apt-key add
                        ;;
                esac
            fi

            # Update package index
            apt update

            ;;
        *CentOS*)
            case $VER in
                *6*)
                    ## CentOS 6
                    yum-config-manager --add-repo https://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/CentOS_6/network:messaging:zeromq:release-stable.repo
                    yum-config-manager --enable https://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/CentOS_6/network:messaging:zeromq:release-stable.repo
                    ;;

                *7*)
                    ## CentOS 7
                    yum-config-manager --add-repo https://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/CentOS_7/network:messaging:zeromq:release-stable.repo
                    yum-config-manager --enable https://download.opensuse.org/repositories/network:/messaging:/zeromq:/release-stable/CentOS_7/network:messaging:zeromq:release-stable.repo
                    ;;
            esac

            # No need to update index for YUM

            ;;
        *Darwin*)
            if [ -f "/usr/local/bin/brew" ];
            then
                echo "Homebrew is available"
            else
                echo "Homebrew is not available : install it"
                /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
            fi
            ;;
        *)
            # No repository to add
            ;;
    esac
}

# Installs all the required dependencies dor ingescape. MUST be called before installing the library itself.
function install_deps {
    if [[ "$FORCE_GIT" == "YES" ]]
    then
        install_deps_from_git
    else
        setup_repos
        if [[ "$OS" =~ "Debian" ]]
        then
            install_deps_debian
        elif [[ "$OS" =~ "CentOS" ]]
        then
            install_deps_centos
        elif [[ "$OS" =~ "Darwin" ]]
        then
            install_deps_darwin
        else
            install_deps_from_git
        fi
    fi
}

# Installs the ingescape library itself. Which process to used is determined by OS and VER variables.
function install_ingescape {
    if [[ "$OS" =~ "Debian" ]]
    then
        # Debian
        dpkg -i ${LINUX_PACKAGE_FILE_NAME}.deb
        apt install -fy
    elif [[ "$OS" =~ "CentOS" ]]
    then
        rpm -Uvh ${LINUX_PACKAGE_FILE_NAME}.rpm
    elif [[ "$OS" =~ "Darwin" ]]
    then
        ./${DARWIN_PACKAGE_FILE_NAME}.sh
    #else
        #TODO install from ZIP
    fi
}

function print_usage {
  cat <<EOF
Usage: $0 [options]
Options: [defaults in brackets after descriptions]
  -h, --help       print this message
  --only-deps      only install dependencies, not ingescape
  --devel          install the development versions of the dependencies
  --force-git      force install from git repositories (instead of using the distribution's packages)
EOF
}


## Initialisation

# Exit on error
set -o errexit

# Exit on unknown variable used
set -o nounset

# Return code for piped sequences is the last command that returned non-zero (we don't have pipes for now)
set -o pipefail

# Print out every command executed (debug)
set -o xtrace


## Actual script

ONLY_DEPS=NO
DEVEL_LIBS=NO
FORCE_GIT=NO

# Parse arguments
for arg in "$@"
do
    case ${arg} in
        --only-deps)
            ONLY_DEPS=YES
            ;;
        --devel)
            DEVEL_LIBS=YES
            ;;
        --force-git)
            FORCE_GIT=YES
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            echo Unknown parameter ${arg}
            print_usage
            exit 1
            ;;
    esac
done

echo ONLY_DEPS  = ${ONLY_DEPS}
echo DEVEL_LIBS = ${DEVEL_LIBS}
echo FORCE_GIT  = ${FORCE_GIT}

discover_os
discover_arch

install_deps

if [[ "$ONLY_DEPS" == "NO" ]]
then
    install_ingescape
fi

## EOF ##

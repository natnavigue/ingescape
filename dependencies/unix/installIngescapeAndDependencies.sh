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

# Directory the script is in (base direcotry)
SCRIPT_DIR="$(dirname $0)"

# Checks whether the current user is root or not and make use of 'sudo' if needed.
#FIXME What if the user does not have sudo access rights ?
function _check_sudo {
    if [[ $EUID = 0 ]]
    then
        $@
    else
        sudo $@
    fi
}

# Use git to retrieve dependency sources and build them using autogen + configure + make
# param $1 the directory in which the git repository will be cloned
# param $2+ the git command to clone the repository
function _clone_and_build {
    local dirname=$1
    shift
    local git_cmd=$@

    echo ""
    echo "Installation of '$dirname' through git..."

    if [[ -d $dirname ]]
    then
        if [[ "$FORCE_ERASE" == "YES" ]]
        then
            echo "Cleaning previous '$dirname' directory (--force-erase)"
            rm -rf $dirname
        else
            echo -n "Directory '$dirname' already exists. Overwrite it (Y/N) ? [N] "
            read erase
            if [[ "$erase" =~ [yY] ]]
            then
                echo "Cleaning previous '$dirname' directory"
                rm -rf $dirname
            else
                echo "Skipping '$dirname'..."
                exit 0
            fi
        fi
    fi

    $git_cmd
    cd $dirname
    ./autogen.sh
    if [[ $dirname == "libzmq" ]]
    then
        ./configure --with-sodium
    else
        ./configure
    fi
    make --jobs=${JOBS}
    _check_sudo make --jobs=${JOBS} install
    _check_sudo ldconfig
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
    armv7*)
        ARCH=armhf  # ARMv7 (armhf)
        ;;
    *)
        # leave ARCH as-is
        ;;
    esac
}

function install_deps_raspbian {
    # Same as Debian
    install_deps_debian $@
}

function install_deps_debian {
    local lib_list=""

    # ZeroMQ reposirory does not provide packages for armv7a (aka. armhf). Hence the build-dependencies required for armv7.
    if [[ "$ARCH" == "armhf" || $VER =~ "9" ]]
    then
        lib_list="build-essential git autoconf automake libtool pkg-config unzip"
    else
        lib_list="libzmq5 libsodium23 czmq zyre"
    fi

    # Check if development libs are requested by user
    if [[ "$DEVEL_LIBS" == "YES" ]]
    then
        # Again, only libsodium is available through the official repository
        if [[ "$ARCH" != "armhf" && $VER =~ "10" ]]
        then
            lib_list="${lib_list} libzmq3-dev libzyre-dev libczmq-dev libsodium-dev"
        fi
    fi

    # Install available packages
    _check_sudo apt-get update && apt-get install -y $lib_list

    # Installing missing packages for armv7l (aka. armhf)
    if [[ "$ARCH" == "armhf" || $VER =~ "9" ]]
    then
        ( # libsodium
            _clone_and_build libsodium git clone --depth 1 -b stable https://github.com/jedisct1/libsodium.git
        )
        ( # libzmq
            _clone_and_build libzmq git clone git://github.com/zeromq/libzmq.git
        )
        ( # czmq
            _clone_and_build czmq git clone git://github.com/zeromq/czmq.git
        )
        ( # zyre
            _clone_and_build zyre git clone git://github.com/zeromq/zyre.git
        )
    fi
}

function install_deps_centos {
    # Falling back to compiling dependencies from sources
    install_deps_from_git
}

function install_deps_darwin {
    # Brew install does not seem to upgrade a formula if it is already installed 
    # We try to upgrade only if the install fails (surely because an older version was already installed...)
    brew install libsodium || brew upgrade libsodium
    brew install zeromq    || brew upgrade zeromq
    brew install czmq      || brew upgrade czmq
    brew install zyre      || brew updgrade zyre
}

function install_deps_from_git {
    ( # libsodium
        _clone_and_build libsodium git clone --depth 1 -b stable https://github.com/jedisct1/libsodium.git
    )
    ( # libzmq
        _clone_and_build libzmq git clone git://github.com/zeromq/libzmq.git
    )
    ( # czmq
        _clone_and_build czmq git clone git://github.com/zeromq/czmq.git
    )
    ( # zyre
        _clone_and_build zyre git clone git://github.com/zeromq/zyre.git
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
		    unset wget_missing
		    unset gnupg_missing
		    command -v wget > /dev/null 2>&1 || export wget_missing=1
		    command -v gpg > /dev/null 2>&1 || export gnupg_missing=1

		    if [[ -n ${wget_missing+x} ]]
		    then
			    if [[ -n ${gnupg_missing+x} ]]
			    then
				    echo "Commands 'gnupg' and 'wget' are missing. You need them to install all the dependencies."
				    echo -n "Install 'gnupg' and 'wget' now (yes|no)? [no] "
				    read response
				    if [[ $response == "yes" ]]
				    then
					    _check_sudo apt-get update && apt-get install -y wget gnupg
				    else
					    echo "Installation stopped by user."
					    echo "You can try to install ingescape alone (without dependencies) with the option '--no-deps'."
					    return 1
				    fi
			    else
				    echo "Command and 'wget' is missing. You need it to install all the dependencies."
				    echo -n "Install 'wget' now (yes|no)? [no] "
				    read response
				    if [[ $response == "yes" ]]
				    then
					    _check_sudo apt-get update && apt-get install -y wget
				    else
					    echo "Installation stopped by user."
					    echo "You can try to install ingescape alone (without dependencies) with the option '--no-deps'."
					    return 1
				    fi
			    fi
		    elif [[ -n ${gnupg_missing+x} ]]
		    then
			    echo "Command 'gnupg' are missing. You need it to install all the dependencies."
			    echo -n "Install 'gnupg' now (yes|no)? [no] "
			    read response
			    if [[ $response == "yes" ]]
			    then
				    _check_sudo apt-get update && apt-get install -y gnupg
			    else
				    echo "Installation stopped by user."
				    echo "You can try to install ingescape alone (without dependencies) with the option '--no-deps'."
				    return 1
			    fi
		    fi
		    unset wget_missing
		    unset gnupg_missing
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
            apt-get update

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
        elif [[ "$OS" =~ "Raspbian" ]]
        then
            install_deps_raspbian
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
    if [[ "$OS" =~ "Debian" || "$OS" =~ "Raspbian" ]]
    then
        # We do not yet build a package for Debian armv7. Falling back to a ZIP installtion.
        if [[ $ARCH == "armhf" ]]
        then
            unzip ${SCRIPT_DIR}/${LINUX_PACKAGE_FILE_NAME}.zip
            _check_sudo cp -rv ${SCRIPT_DIR}/${LINUX_PACKAGE_FILE_NAME}/* /usr/local/
            rm -rf ${SCRIPT_DIR}/${LINUX_PACKAGE_FILE_NAME}
        else
            _check_sudo dpkg -i ${SCRIPT_DIR}/${LINUX_PACKAGE_FILE_NAME}.deb
            _check_sudo apt install -fy
        fi
    elif [[ "$OS" =~ "CentOS" ]]
    then
        _check_sudo rpm -Uvh ${SCRIPT_DIR}/${LINUX_PACKAGE_FILE_NAME}.rpm
    elif [[ "$OS" =~ "Darwin" ]]
    then
        _check_sudo ${SCRIPT_DIR}/${DARWIN_PACKAGE_FILE_NAME}.sh --prefix=/usr/local/
    else # Falling back to ZIP installation
        unzip ${SCRIPT_DIR}/${LINUX_PACKAGE_FILE_NAME}.zip
        _check_sudo cp -rv ${SCRIPT_DIR}/${LINUX_PACKAGE_FILE_NAME}/* /usr/local/
        rm -rf ${SCRIPT_DIR}/${LINUX_PACKAGE_FILE_NAME}
    fi
}

function print_usage {
  cat <<EOF
Usage: $0 [options]
Options:
  -h, --help       print this message
  --deps-only      only install dependencies, not ingescape
  --devel          install the development versions of the dependencies
  --force-git      force install from git repositories (instead of using the distribution's packages)
  --force-erase    force erasure of any existing dependency local directory (user input needed otherwise)
  --jobs=<num>     run 'make' commands with <num> parallel jobs
  --no-deps        do not install dependencies, just ingescape
  -v, --verbose    show debug trace during execution
EOF
}

function _check_opt_validity {
    if [[ "$NO_DEPS" == "YES" && "$DEPS_ONLY" == "YES" ]]
    then
        echo Option --deps-only incompatible with --no-deps. Exiting.
        print_usage
        exit 1
    fi

    if [[ "$NO_DEPS" == "YES" && "$FORCE_GIT" == "YES" ]]
    then
        echo Option --no-only incompatible with --force-git. Exiting.
        print_usage
        exit 1
    fi

    if [[ "$NO_DEPS" == "YES" && "$FORCE_ERASE" == "YES" ]]
    then
        echo Option --no-deps incompatible with --force-erase. Exiting.
        print_usage
        exit 1
    fi
}


## Initialisation

# Exit on error
set -o errexit

# Exit on unknown variable used
set -o nounset

# Return code for piped sequences is the last command that returned non-zero (we don't have pipes for now)
set -o pipefail

## Actual script

DEPS_ONLY=NO
DEVEL_LIBS=NO
FORCE_ERASE=NO
FORCE_GIT=NO
JOBS=1
NO_DEPS=NO
VERBOSE=NO

# Parse arguments
for arg in "$@"
do
    case ${arg} in
        --deps-only)
            DEPS_ONLY=YES
            ;;
        --no-deps)
            NO_DEPS=YES
            ;;
        --devel)
            DEVEL_LIBS=YES
            ;;
        --force-erase)
            FORCE_ERASE=YES
            ;;
        --force-git)
            FORCE_GIT=YES
            ;;
        --jobs=*)
            JOBS=${arg#*=}
            ;;
        -v|--verbose)
            VERBOSE=YES
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


if [[ "$VERBOSE" == "YES" ]]
then

    # Print out every command executed (debug)
    set -o xtrace

    echo DEPS_ONLY   = ${DEPS_ONLY}
    echo DEVEL_LIBS  = ${DEVEL_LIBS}
    echo FORCE_ERASE = ${FORCE_ERASE}
    echo FORCE_GIT   = ${FORCE_GIT}
    echo JOBS        = ${JOBS}
    echo NO_DEPS     = ${DEPS_ONLY}
    echo VERBOSE     = ${VERBOSE}
fi

_check_opt_validity

discover_os
discover_arch

if [[ "$NO_DEPS" == "YES" ]]
then
    echo "Option --no-deps provided. Skipping dependencies installation."
else
    echo "Installing dependencies..."
    echo "--------------------------"
    install_deps
fi

echo ""

if [[ "$DEPS_ONLY" == "YES" ]]
then
    echo "Option --deps-only provided. Skipping ingescape installation."
else
    echo "Installing ingescape..."
    echo "-----------------------"
    install_ingescape
fi

echo ""
echo "Installation completed with success!"

## EOF ##

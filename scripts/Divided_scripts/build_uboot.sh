#!/bin/bash

# Script to build u-boot + preloader for Altera Soc Platform (Only Nano / Atlas board initially)
# usage: build_uboot.sh <builddir path>
#------------------------------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------------------------------
CURRENT_DIR=`pwd`
WORK_DIR=$1

UBOOT_DIR=${WORK_DIR}/uboot
distro=jessie

#-------------------------------------------
# u-boot, toolchain, imagegen vars
#-------------------------------------------

CC_DIR="${WORK_DIR}/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux"
CC_URL="https://releases.linaro.org/14.09/components/toolchain/binaries/gcc-linaro-arm-linux-gnueabihf-4.9-2014.09_linux.tar.bz2"

CC_FILE="${CC_DIR}.tar.bz2"
CC="${CC_DIR}/bin/arm-linux-gnueabihf-"

#UBOOT_VERSION=''
#UBOOT_VERSION='v2015.10'
UBOOT_VERSION='v2016.01-rc2'
CHKOUT_OPTIONS=''
#CHKOUT_OPTIONS='-b tmp'

BOARD_CONFIG='socfpga_de0_nano_soc_defconfig'
MAKE_CONFIG='u-boot-with-spl-dtb.sfp'

UBOOT_SPLFILE=${UBOOT_DIR}/u-boot-with-spl-dtb.sfp

NCORES=`nproc`

extract_toolchain() {
    if hash lbzip2 2>/dev/null; then
        echo "lbzip2 found"
        tar --use=lbzip2 -xf ${CC_FILE}
    else
        echo "lbzip2 not found using tar simglecore extract"
        tar xf ${CC_FILE}
    fi
}


function get_toolchain {
# download linaro cross compiler toolchain

if [ ! -d ${CC_DIR} ]; then
    if [ ! -f ${CC_FILE} ]; then
        echo "downloading toolchain"
    	wget -c ${CC_URL}
    fi
# extract linaro cross compiler toolchain
# uses multicore extract (lbzip2) if available

    echo "extracting toolchain" 
    extract_toolchain
#	
	
fi
}

function fetch_uboot {
# Fetch uboot

if [ ! -f ${UBOOT_DIR} ]; then
    echo "cloning u-boot"
    git clone git://git.denx.de/u-boot.git uboot
fi

cd $UBOOT_DIR
if [ ! -z "$UBOOT_VERSION" ]
then
    git checkout $UBOOT_VERSION $CHKOUT_OPTIONS
fi
cd ..
}

install_sid_armhf_crosstoolchain() {
sudo dpkg --add-architecture armhf
sudo apt-get update

#sudo apt-get install crossbuild-essential-armhf
#sudo apt-get install gcc-arm-linux-gnueabihf

sudo apt-get install gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf libc6-dev debconf dpkg-dev libconfig-auto-perl file libfile-homedir-perl libfile-temp-perl liblocale-gettext-perl perl binutils-multiarch fakeroot

}

function build_uboot {
# compile u-boot + spl
export ARCH=arm
export PATH=$CC_DIR/bin/:$PATH
export CROSS_COMPILE=$CC

echo "compiling u-boot"
make mrproper
make $BOARD_CONFIG
make $MAKE_CONFIG -j$NCORES
}

# run functions
echo "#---------------------------------------------------------------------------------- "
echo "#-------------+++      build_uboot.sh Start      +++------------------------------- "
echo "#---------------------------------------------------------------------------------- "

set -e

if [ ! -z "$WORK_DIR" ]; then
    cd $WORK_DIR
    get_toolchain
    fetch_uboot
    cd $UBOOT_DIR
    build_uboot
else
    echo "no workdir parameter given"
    echo "usage: build_uboot.sh <builddir path>"
fi
echo "#---------------------------------------------------------------------------------- "
echo "#-------------+++      build_uboot.sh End      +++--------------------------------- "
echo "#---------------------------------------------------------------------------------- "



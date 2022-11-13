#!/bin/bash
OPATH=$PATH
. edk2.sh
#
# Customize the following varaible to fit yours.
#
TARGET=RELEASE # NOOPT # DEBUG # 

build -a AARCH64 -t GCC5 -b $TARGET -p my-platforms/Platform/RaspberryPi/RPi4/RPi4.dsc
export PATH=$OPATH
#
# Customize the following varaible to fit yours.
#
# RELEASE_FOLDER=/home/pxing/AmpereR/RPi4/$TARGET
if [[ ! -z ${RELEASE_FOLDER} ]]; then
    echo copy FD to $RELEASE_FOLDER...
    mkdir -p $RELEASE_FOLDER
    cp -f ./Build/RPi4/"$TARGET"_GCC5/FV/RPI_EFI.fd $RELEASE_FOLDER/RPI_EFI.fd
fi

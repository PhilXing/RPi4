#!/bin/bash
# WORKSPACE="`dirname $0`"
# WORKSPACE="`readlink -f \"$WORKSPACE\"`"
# export WORKSPACE

export WORKSPACE=$PWD
export PACKAGES_PATH=$WORKSPACE/my-platforms:$WORKSPACE/edk2:$WORKSPACE/edk2-platforms:$WORKSPACE/edk2-non-osi
export GCC5_AARCH64_PREFIX=aarch64-linux-gnu-
export GCC5_ARM_PREFIX=$GCC5_AARCH64_PREFIX
export CROSS_COMPILE=$GCC5_AARCH64_PREFIX
# export HOST_ARCH=X64
export PATH=$WORKSPACE/toolchain/gcc-linaro-7.5.0-2019.12-x86_64_aarch64-linux-gnu/bin:"${PATH}" # path for GCC
export PATH=$WORKSPACE/toolchain/iasl:"${PATH}"
export PYTHON_COMMAND=/usr/bin/python3.8
source edk2/edksetup.sh
if ! [ -d "$WORKSPACE/edk2/BaseTools/Source/C/bin" ] ; then
    make -C edk2/BaseTools
fi

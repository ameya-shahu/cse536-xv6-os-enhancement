#!/bin/bash -e

# Install pre-requisites
sudo apt-get install autoconf automake autotools-dev curl \
    python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential \
    bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev

pushd ../
    # Clone the RISC-V GNU repo
    [ ! -d "riscv-gnu-toolchain" ] && \
        git clone https://github.com/riscv-collab/riscv-gnu-toolchain.git

    TOOLCHAIN_DIR=`pwd`/riscv-gnu-toolchain/build

    # Go to cloned folder
    pushd riscv-gnu-toolchain
        mkdir -p build
        ./configure --prefix=$TOOLCHAIN_DIR
        make -j`nproc`
    popd

    echo "Installed RISC-V GNU toolchain to $TOOLCHAIN_DIR"
popd

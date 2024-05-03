#!/bin/bash -e

sudo apt install ninja-build

pushd ../
    [ ! -d "riscv-qemu" ] && git clone https://github.com/qemu/qemu && mv -f qemu riscv-qemu

    QEMU_PATH=`pwd`/riscv-qemu/build

    pushd riscv-qemu
        git checkout v6.0.0
        ./configure --target-list=riscv64-softmmu
        make -j $(nproc)
    popd

    echo "[*] Installed RISC-V QEMU to $QEMU_PATH."
popd
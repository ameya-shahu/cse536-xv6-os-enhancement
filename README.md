# CSE 536 Advanced Operating System Assignments : xv6 Enhancements

In ASU's Advanced Operating System course (CSE 536), we are using the xv6 Operating System for programming assignments. xv6 is a teaching-focused OS designed by some incredible folks at MIT ([link](https://github.com/mit-pdos/xv6-riscv.git)). This README explains how to setup QEMU and a GNU RISC-V toolchain, needed for running xv6, as well how to boot up a QEMU VM with xv6 and different enhancements done as a part of course assignments.

## Assignments Summary
1. Assignment 0: Introduction to QEMU and xv6 Installation. This assignment guides through the initial setup, including installing QEMU and setting up the xv6 operating system environment. Get started with the essentials for exploring and working with xv6.

2. Assignment 1: Boot ROM, Bootloader, and Secure Boot with PMP. Delve into the foundational elements of boot processes with this assignment. Learned about boot ROM, bootloader functionality, and explore secure boot mechanisms, including Physical Memory Protection (PMP), to ensure system integrity and security.

3. Assignment 2: Memory Management and Paging Techniques. Dive deeper into memory management concepts with this assignment. Implemented on-demand paging and copy-on-write mechanisms using page faults within the xv6 operating system. Explored dynamic page allocation, page fault handling, and disk swapping to enhance memory efficiency and performance.

4. Assignment 3: Implementation of User-Level Threads and Scheduling Policies. engages with the complexities of process management within the xv6 operating system. implemented user-level threads, also known as self-threads, within xv6 processes. By partitioning the kernel-supported thread into multiple user-level threads and designating one as the user-level scheduler, explore a variety of scheduling algorithms to determine optimal thread execution within the process.

5. Assignment 4: Trap and Emulate Virtual Machine Design. implemented a virtual machine where user-level instructions execute directly, while supervisor-level instructions are trapped and emulated by the host operating system acting as a virtual machine monitor.

## A. Installing xv6 pre-requisites 

Please reach out to the TAs if you have any installation issues.

#### Linux/WSL

1. Navigate to the assignment0-installation/install/linux-wsl folder
2. Install RISC-V QEMU: `./linux-qemu.sh`
3. Install RISC-V toolchain:`./linux-toolchain.sh`
4. Add installed binaries to path: `source .add-linux-paths`

#### MacOS

1. Navigate to the assignment0-installation/install/mac folder
2. Install RISC-V QEMU: `./mac-qemu.sh`
3. Install RISC-V toolchain: `./mac-toolchain.sh`
4. Add installed binaries to path: `source .add-mac-paths`

#### Installing using package manager
If installing QEMU and the toolchain from source does not work for you, then do the following steps:

1. Linux/WSL
    1. sudo apt-get update
    2. sudo apt-get install git build-essential gdb-multiarch qemu-system-misc gcc-riscv64-linux-gnu binutils-riscv64-linux-gnu 
2. Mac (work in progress)
    1. xcode-select --install
    2. /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    3. (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
    4. eval "$(/opt/homebrew/bin/brew shellenv)"
    5. brew tap riscv/riscv
    6. brew install riscv-tools
    7. Write the follwing line to ~/.zshrc " export PATH="/opt/homebrew/Cellar/riscv-gnu-toolchain/main/bin:$PATH" "
    8. source ~/.zshrc
    9. brew install qemu
    10. brew link qemu
    11. brew link --overwrite qemu (Run this if you can't link qemu due to any conflicts)

## B. Running the xv6 OS

1. Navigate back to main folder and clone the xv6 OS using 

        git clone https://github.com/mit-pdos/xv6-riscv.git

2. Navigate to xv6-riscv and run `make qemu`

## C. FAQs

1. While running linux-qemu.sh, if you run into `ERROR: glib-2.48 gthread-2.0 is required to compile QEMU`, then :

- Run this command in the terminal.  `sudo apt install libglib2.0-dev`. This is caused due to a newer version of your linux distro([link](https://github.com/Xilinx/qemu/issues/40)). 

2. linux-qemu.sh : `../meson.build:328:2: ERROR: Dependency "pixman-1" not found, tried pkgconfig`

- Can be resolved by running `sudo apt install libpixman-1-dev` ([link](https://stackoverflow.com/a/39916441))

## Acknowledgement

We remain thankful to the xv6 team at MIT for their open-source codebase. 

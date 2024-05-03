# Install brew if not installed
which -s brew
if [[ $? != 0 ]] ; then
    # Install Homebrew
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    brew update
fi

# Install some pre-requisite packages
brew install pkg-config glib pixman ninja

# Install qemu
pushd ../
    [ ! -d "qemu" ] && git clone https://git.qemu.org/git/qemu.git

    pushd qemu
        git submodule init
        git submodule update --recursive

        mkdir objdir
        pushd objdir
            ../configure --target-list=riscv64-softmmu
            make -j `sysctl -n hw.ncpu`
        popd
    popd
popd

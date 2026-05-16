#!/usr/bin/env bash
set -eoux pipefail

# Install build dependencies
dnf install -y \
    kernel-devel \
    kernel-headers \
    make \
    gcc \
    git \
    dkms

# Get the running kernel version in the build container
KERNEL_VERSION=$(rpm -q --qf '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-devel | head -1)

# Clone the tspc branch (with submodules for hid-tminit)
git clone --recurse-submodules \
    --branch tspc \
    https://github.com/Kimplul/hid-tmff2.git \
    /tmp/hid-tmff2

cd /tmp/hid-tmff2

# Build against the installed kernel headers
make -C /usr/src/kernels/${KERNEL_VERSION} \
    M=$(pwd) \
    modules

# Install the modules
make -C /usr/src/kernels/${KERNEL_VERSION} \
    M=$(pwd) \
    INSTALL_MOD_PATH=/usr \
    modules_install

# Rebuild module dependencies
depmod -a ${KERNEL_VERSION}

# Install udev rules (fixes permission issues, especially for Proton/Steam)
make udev-rules

# Clean up
cd /
rm -rf /tmp/hid-tmff2
dnf remove -y git dkms
dnf clean all

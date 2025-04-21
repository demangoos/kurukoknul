#!/usr/bin/env bash
#
# Copyright (C) 2022-2023 Neebe3289 <neebexd@gmail.com>
# Enhanced by Claude (April 2025)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Enhanced script for kernel compilation with visual improvements

# ═══════════════════════════════════════════════
# Color codes for better readability
# ═══════════════════════════════════════════════
RED="\033[1;31m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA="\033[1;35m"
CYAN="\033[1;36m"
WHITE="\033[1;37m"
BOLD="\033[1m"
NC="\033[0m" # No Color

# ═══════════════════════════════════════════════
# Progress bar function
# ═══════════════════════════════════════════════
show_progress() {
  local duration=$1
  local prefix=$2
  local width=50
  local character="▓"
  local empty="░"
  local elapsed=0
  local interval=0.1
  local steps=$(bc <<< "$duration/$interval")
  local step_size=$(bc -l <<< "$width/$steps")
  local current_step=0

  printf "\n"
  while [ $elapsed -lt $duration ]; do
    current_step=$(bc -l <<< "$elapsed/$interval*$step_size" | cut -d. -f1)
    printf "\r${CYAN}${prefix} [${NC}"
    for ((i=0; i<$width; i++)); do
      if [ $i -lt $current_step ]; then
        printf "${GREEN}${character}${NC}"
      else
        printf "${YELLOW}${empty}${NC}"
      fi
    done
    printf "${CYAN}] ${elapsed}/${duration}s${NC}"
    sleep $interval
    elapsed=$(($elapsed + 1))
  done
  printf "\n"
}

# ═══════════════════════════════════════════════
# Display functions
# ═══════════════════════════════════════════════
print_header() {
  clear
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║                                                                ║${NC}"
  echo -e "${CYAN}║  ${BOLD}${MAGENTA}🥭 KERNEL BUILD SCRIPT ${YELLOW}v2.0${NC} ${CYAN}║${NC}"
  echo -e "${CYAN}║  ${WHITE}Automated kernel compilation tool     ${NC}    ${CYAN}║${NC}"
  echo -e "${CYAN}║                                                                ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

print_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

print_section() {
  echo ""
  echo -e "${CYAN}══════════════════ ${BOLD}$1${NC} ${CYAN}══════════════════${NC}"
}

print_build_success() {
  echo ""
  echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║                                                                ║${NC}"
  echo -e "${GREEN}║  ${BOLD}${WHITE}✅ BUILD SUCCESSFULLY COMPLETED!${NC}                           ${GREEN}║${NC}"
  echo -e "${GREEN}║                                                                ║${NC}"
  echo -e "${GREEN}║  ${WHITE}Device: ${YELLOW}${DEVICE_MODEL} (${DEVICE_CODENAME})${NC}                      ${GREEN}║${NC}"
  echo -e "${GREEN}║  ${WHITE}Kernel: ${YELLOW}${KERNEL_NAME} ${SUBLEVEL} ${KERNEL_VARIANT}${NC}                           ${GREEN}║${NC}"
  echo -e "${GREEN}║  ${WHITE}Build time: ${YELLOW}${hours}h ${minutes}m ${seconds}s${NC}                               ${GREEN}║${NC}"
  echo -e "${GREEN}║  ${WHITE}Compiler: ${YELLOW}${ClangName}${NC}                                         ${GREEN}║${NC}"
  echo -e "${GREEN}║  ${WHITE}Output: ${YELLOW}~/${KERNEL_ZIP}${VARIANT}.zip${NC}                           ${GREEN}║${NC}"
  echo -e "${GREEN}║                                                                ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

print_build_failed() {
  echo ""
  echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║                                                                ║${NC}"
  echo -e "${RED}║  ${BOLD}${WHITE}❌ BUILD FAILED!${NC}                                             ${RED}║${NC}"
  echo -e "${RED}║                                                                ║${NC}"
  echo -e "${RED}║  ${WHITE}Please check the error messages above.${NC}                        ${RED}║${NC}"
  echo -e "${RED}║  ${WHITE}Output log saved to: ${YELLOW}${MainPath}/out/output.txt${NC}               ${RED}║${NC}"
  echo -e "${RED}║                                                                ║${NC}"
  echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# ═══════════════════════════════════════════════
# Load variables from config.env
# ═══════════════════════════════════════════════
export $(grep -v '^#' config.env | xargs)

# ═══════════════════════════════════════════════
# Path definitions
# ═══════════════════════════════════════════════
MainPath="$(readlink -f -- $(pwd))"
MainClangPath="${MainPath}/clang"
AnyKernelPath="${MainPath}/anykernel"
CrossCompileFlagTriple="aarch64-linux-gnu-"
CrossCompileFlag64="aarch64-linux-gnu-"
CrossCompileFlag32="arm-linux-gnueabi-"

# ═══════════════════════════════════════════════
# Clone toolchain function
# ═══════════════════════════════════════════════
[[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
function getclang() {
  print_section "Toolchain Setup"
  
  if [ "${ClangName}" = "azure" ]; then
    if [ ! -f "${MainClangPath}-azure/bin/clang" ]; then
      print_info "Clang is set to azure, cloning it..."
      git clone https://gitlab.com/Panchajanya1999/azure-clang clang-azure --depth=1
      ClangPath="${MainClangPath}"-azure
      export PATH="${ClangPath}/bin:${PATH}"
      cd ${ClangPath}
      wget "https://gist.github.com/dakkshesh07/240736992abf0ea6f0ee1d8acb57a400/raw/a835c3cf8d99925ca33cec3b210ee962904c9478/patch-for-old-glibc.sh" -O patch.sh && chmod +x patch.sh && ./patch.sh
      cd ..
    else
      print_info "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-azure
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "neutron" ] || [ "${ClangName}" = "" ]; then
    if [ ! -f "${MainClangPath}-neutron/bin/clang" ]; then
      print_info "Clang is set to neutron, cloning it..."
      mkdir -p "${MainClangPath}"-neutron
      ClangPath="${MainClangPath}"-neutron
      export PATH="${ClangPath}/bin:${PATH}"
      cd ${ClangPath}
      curl -LOk "https://raw.githubusercontent.com/Neutron-Toolchains/antman/main/antman"
      chmod +x antman && ./antman -S
      ./antman --patch=glibc
      cd ..
    else
      print_info "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-neutron
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "proton" ]; then
    if [ ! -f "${MainClangPath}-proton/bin/clang" ]; then
      print_info "Clang is set to proton, cloning it..."
      git clone https://github.com/kdrag0n/proton-clang clang-proton --depth=1
      ClangPath="${MainClangPath}"-proton
      export PATH="${ClangPath}/bin:${PATH}"
    else
      print_info "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-proton
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "zyc" ]; then
    if [ ! -f "${MainClangPath}-zyc/bin/clang" ]; then
      print_info "Clang is set to zyc, cloning it..."
      mkdir -p ${MainClangPath}-zyc
      cd clang-zyc
      wget -q $(curl -k https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-link.txt 2>/dev/null) -O "zyc-clang.tar.gz"
      tar -xf zyc-clang.tar.gz
      ClangPath="${MainClangPath}"-zyc
      export PATH="${ClangPath}/bin:${PATH}"
      rm -f zyc-clang.tar.gz
      cd ..
    else
      print_info "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-zyc
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "clang17" ]; then
    if [ ! -f "${MainClangPath}-clang17/bin/clang" ]; then
      print_info "Clang is set to Clang 17, downloading it..."
      mkdir -p "${MainClangPath}-clang17"
      ClangPath="${MainClangPath}-clang17"
      cd "${MainClangPath}-clang17"
      wget https://github.com/llvm/llvm-project/releases/download/llvmorg-17.0.6/clang+llvm-17.0.6-x86_64-linux-gnu-ubuntu-22.04.tar.xz -O clang17.tar.xz
      tar -xf clang17.tar.xz --strip-components=1
      rm -f clang17.tar.xz
      export PATH="${ClangPath}/bin:${PATH}"
      cd "${MainPath}"
    else
      print_info "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}-clang17"
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "greenforce" ]; then
    if [ ! -f "${MainClangPath}-greenforce/bin/clang" ]; then
      print_info "Clang is set to greenforce, cloning it..."
      mkdir -p ${MainClangPath}-greenforce
      cd clang-greenforce
      wget -q https://raw.githubusercontent.com/greenforce-project/greenforce_clang/main/get_latest_url.sh
      source get_latest_url.sh; rm -rf get_latest_url.sh
      wget -q $LATEST_URL_GZ -O "greenforce-clang.tar.gz"
      tar -xf greenforce-clang.tar.gz
      ClangPath="${MainClangPath}"-greenforce
      export PATH="${ClangPath}/bin:${PATH}"
      rm -f greenforce-clang.tar.gz
      cd ..
    else
      print_info "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-greenforce
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "android-llvm" ]; then
    if [ ! -f "${MainClangPath}-android-llvm/bin/clang" ]; then
      print_info "Clang is set to android-llvm, cloning it..."
      mkdir -p ${MainClangPath}-android-llvm
      ClangPath="${MainClangPath}"-android-llvm
      
      # Get Android LLVM Toolchain - Using a pre-built version from GitHub mirror
      cd ${MainPath}
      git clone --depth=1 https://github.com/ZyCromerZ/android-kernel-clang clang-android-llvm
      export PATH="${ClangPath}/bin:${PATH}"
      cd ..
    else
      print_info "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-android-llvm
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "aosp" ]; then
    if [ ! -f "${MainClangPath}-aosp/bin/clang" ]; then
      print_info "Clang is set to AOSP, cloning it..."
      mkdir -p ${MainClangPath}-aosp
      ClangPath="${MainClangPath}"-aosp
      
      # Menggunakan mirror AOSP Clang dari GitHub yang sudah dikemas
      cd ${MainPath}
      git clone --depth=1 https://github.com/kdrag0n/arm64-gcc.git clang-aosp
      export PATH="${ClangPath}/bin:${PATH}"
      cd ..
    else
      print_info "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-aosp
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "weebx" ]; then
    if [ ! -f "${MainClangPath}-weebx/bin/clang" ]; then
      print_info "Clang is set to WeebX, cloning it..."
      mkdir -p ${MainClangPath}-weebx
      ClangPath="${MainClangPath}"-weebx
      cd ${MainPath}
      
      # Get WeebX Clang - direct download from fixed release
      git clone --depth=1 https://github.com/XSans0/WeebX-Clang.git -b main clang-weebx
      export PATH="${ClangPath}/bin:${PATH}"
      cd ..
    else
      print_info "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-weebx
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  elif [ "${ClangName}" = "arter" ]; then
    if [ ! -f "${MainClangPath}-arter/bin/clang" ]; then
      print_info "Clang is set to Arter, cloning it..."
      mkdir -p ${MainClangPath}-arter
      ClangPath="${MainClangPath}"-arter
      cd ${MainPath}
      
      # Get Arter97 clang
      git clone --depth=1 https://github.com/arter97/arm64-gcc clang-arter
      export PATH="${ClangPath}/bin:${PATH}"
      cd ..
    else
      print_info "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-arter
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  # Menambahkan opsi Eva GCC
  elif [ "${ClangName}" = "eva" ]; then
    if [ ! -f "${MainClangPath}-eva/bin/clang" ]; then
      print_info "Clang is set to Eva GCC, cloning it..."
      mkdir -p ${MainClangPath}-eva
      ClangPath="${MainClangPath}"-eva
      cd ${MainPath}
      
      # Get Eva GCC
      git clone --depth=1 https://github.com/mvaisakh/gcc-arm64.git clang-eva
      export PATH="${ClangPath}/bin:${PATH}"
      cd ..
    else
      print_info "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}"-eva
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  # Menambahkan opsi untuk Snapdragon LLVM
  elif [ "${ClangName}" = "snapdragon" ]; then
    if [ ! -f "${MainClangPath}-snapdragon/bin/clang" ]; then
      print_info "Clang is set to Snapdragon LLVM, cloning it..."
      mkdir -p "${MainClangPath}-snapdragon"
      ClangPath="${MainClangPath}-snapdragon"
      
      # Clone Snapdragon LLVM di direktori yang benar
      cd "${MainPath}"
      git clone --depth=1 https://github.com/ThankYouMario/proprietary_vendor_qcom_sdclang -b 14 "${ClangPath}"
      export PATH="${ClangPath}/bin:${PATH}"
      cd "${MainPath}"
    else
      print_info "Clang already exists. Skipping..."
      ClangPath="${MainClangPath}-snapdragon"
      export PATH="${ClangPath}/bin:${PATH}"
    fi
  else
    print_error "Incorrect clang name. Check config.env for clang names."
    exit 1
  fi
  if [ -f "${ClangPath}/bin/clang" ]; then
    export KBUILD_COMPILER_STRING="$(${ClangPath}/bin/clang --version | head -n 1)"
    print_success "Using compiler: ${KBUILD_COMPILER_STRING}"
  else
    export KBUILD_COMPILER_STRING="Unknown"
    print_warning "Could not determine compiler version"
  fi
}

# ═══════════════════════════════════════════════
# Update clang function
# ═══════════════════════════════════════════════
function updateclang() {
  print_section "Toolchain Update Check"
  
  [[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
  if [ "${ClangName}" = "neutron" ] || [ "${ClangName}" = "" ]; then
    print_info "Clang is set to neutron, checking for updates..."
    cd clang-neutron
    if [ "$(./antman -U | grep "Nothing to do")" = "" ];then
      print_success "Updates found, applying them..."
      ./antman --patch=glibc
    else
      print_info "No updates have been found, skipping"
    fi
    cd ..
  elif [ "${ClangName}" = "zyc" ]; then
    print_info "Clang is set to zyc, checking for updates..."
    cd clang-zyc
    ZycLatest="$(curl -k https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-lastbuild.txt)"
    if [ "$(cat README.md | grep "Build Date : " | cut -d: -f2 | sed "s/ //g")" != "${ZycLatest}" ];then
      print_success "An update have been found, updating..."
      sudo rm -rf ./*
      wget -q $(curl -k https://raw.githubusercontent.com/ZyCromerZ/Clang/main/Clang-main-link.txt 2>/dev/null) -O "zyc-clang.tar.gz"
      tar -xf zyc-clang.tar.gz
      rm -f zyc-clang.tar.gz
    else
      print_info "No updates have been found, skipping..."
    fi
    cd ..
  elif [ "${ClangName}" = "azure" ]; then
    print_info "Checking for Azure Clang updates..."
    cd clang-azure
    git fetch -q origin main
    git pull origin main
    cd ..
  elif [ "${ClangName}" = "proton" ]; then
    print_info "Checking for Proton Clang updates..."
    cd clang-proton
    git fetch -q origin master
    git pull origin master
    cd ..
  elif [ "${ClangName}" = "android-llvm" ] || [ "${ClangName}" = "aosp" ] || [ "${ClangName}" = "weebx" ] || [ "${ClangName}" = "arter" ] || [ "${ClangName}" = "eva" ] || [ "${ClangName}" = "snapdragon" ]; then
    print_info "Clang is set to ${ClangName}, checking for updates..."
    cd clang-${ClangName}
    git fetch -q origin
    git pull
    cd ..
  fi
}

# ═══════════════════════════════════════════════
# KernelSU function
# ═══════════════════════════════════════════════
function kernelsu() {
    print_section "KernelSU Setup"
    
    if [ "$KERNELSU" = "yes" ];then
          KERNEL_VARIANT="${KERNEL_VARIANT}-KernelSU"
          if [ ! -f "${MainPath}/KernelSU/README.md" ]; then
             cd ${MainPath}
             print_info "Enabling KernelSU in defconfig..."
             sed -i "s/CONFIG_KSU=n/CONFIG_KSU=y/g" arch/${ARCH}/configs/${DEVICE_DEFCONFIG}
             print_success "KernelSU enabled successfully"
          else
             print_info "KernelSU already configured"
          fi
    else
          print_info "KernelSU is disabled"
    fi
}

# ═══════════════════════════════════════════════
# Environmental variables
# ═══════════════════════════════════════════════
DEVICE_MODEL="Poco X5 5G & Redmi Note 12 5G"
DEVICE_CODENAME="stone"
BUILD_TIME="$(TZ="Asia/Jakarta" date "+%Y%m%d")"
export DEVICE_DEFCONFIG="moonstone_defconfig"
export ARCH="arm64"
export KBUILD_BUILD_USER="mangoos"
export KBUILD_BUILD_HOST="github.com"
export KERNEL_NAME="🥭"
export SUBLEVEL="v5.4.$(cat "${MainPath}/Makefile" | grep "SUBLEVEL =" | sed 's/SUBLEVEL = *//g')"
IMAGE="${MainPath}/out/arch/arm64/boot/Image"
DTB_IMAGE="${MainPath}/out/arch/arm64/boot/dts/vendor/xiaomi/moonstone.dtb"
CORES="$(nproc --all)"
BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# ═══════════════════════════════════════════════
# Compilation function
# ═══════════════════════════════════════════════
compile() {
  print_section "Kernel Compilation"
  
  print_info "Device: ${DEVICE_MODEL} (${DEVICE_CODENAME})"
  print_info "Kernel: ${KERNEL_NAME} ${SUBLEVEL} ${KERNEL_VARIANT}"
  print_info "Branch: ${BRANCH}"
  print_info "Compiler: ${ClangName}"
  print_info "Using ${CORES} CPU cores for compilation"

  if [ "$ClangName" = "proton" ] || [ "$ClangName" = "greenforce" ]; then
    print_info "Adjusting LLVM_POLLY for ${ClangName}..."
    sed -i 's/CONFIG_LLVM_POLLY=y/# CONFIG_LLVM_POLLY is not set/g' ${MainPath}/arch/$ARCH/configs/$DEVICE_DEFCONFIG || echo ""
  else
    sed -i 's/# CONFIG_LLVM_POLLY is not set/CONFIG_LLVM_POLLY=y/g' ${MainPath}/arch/$ARCH/configs/$DEVICE_DEFCONFIG || echo ""
  fi
  
  print_info "Generating defconfig..."
  make O=out ARCH=$ARCH $DEVICE_DEFCONFIG
  
  print_info "Starting compilation process..."
  # Show a simulated progress for the make process
  make -j"$CORES" ARCH=$ARCH O=out \
    CC=clang \
    LD=ld.lld \
    LLVM=1 \
    LLVM_IAS=1 \
    AR=llvm-ar \
    NM=llvm-nm \
    OBJCOPY=llvm-objcopy \
    OBJDUMP=llvm-objdump \
    STRIP=llvm-strip \
    CLANG_TRIPLE=${CrossCompileFlagTriple} \
    CROSS_COMPILE=${CrossCompileFlag64} \
    CROSS_COMPILE_ARM32=${CrossCompileFlag32} |& tee out/output.txt &
  
  # Store the PID of the make process
  make_pid=$!
  
  # Display a spinner while compilation is running
  spinner=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  spin_index=0
  start_time=$(date +%s)
  
  while kill -0 $make_pid 2>/dev/null; do
    current_time=$(date +%s)
    elapsed=$((current_time - start_time))
    hours=$((elapsed / 3600))
    minutes=$(((elapsed % 3600) / 60))
    seconds=$((elapsed % 60))
    
    echo -ne "\r${CYAN}[${spinner[$spin_index]}]${NC} Building kernel... ${YELLOW}${hours}h ${minutes}m ${seconds}s${NC} elapsed"
    spin_index=$(((spin_index + 1) % 10))
    sleep 0.1
  done
  
  # Wait for make to finish and capture its exit status
  wait $make_pid
  make_status=$?
  echo "" # New line after spinner
  
  if [ $make_status -eq 0 ] && [ -f "$IMAGE" ]; then
    print_success "Kernel compiled successfully! 🎉"
    cd ${MainPath}
    print_info "Cloning AnyKernel3 repository..."
    git clone --depth=1 ${AnyKernelRepo} -b ${AnyKernelBranch} ${AnyKernelPath}
    cp $IMAGE ${AnyKernelPath}
    if [[ -f "$DTB_IMAGE" ]]; then
      rm -rf ${AnyKernelPath}/dtb
      cp $DTB_IMAGE ${AnyKernelPath}/dtb
      print_success "DTB copied successfully"
    fi
    return 0
  else
    print_build_failed
    if [ "$CLEANUP" = "yes" ]; then
      cleanup
    fi
    exit 1
  fi
}

# ═══════════════════════════════════════════════
# Zipping function
# ═══════════════════════════════════════════════
KERNEL_ZIP="${KERNEL_NAME}-${DEVICE_CODENAME}-${BUILD_TIME}"

function zipping() {
    print_section "Creating Flashable Zip"
    
    cd ${AnyKernelPath} || exit 1
    if [ "$KERNELSU" = "yes" ]; then
      VARIANT="-KernelSU"
      print_info "Preparing KernelSU variant..."
      sed -i "s/kernel.string=.*/kernel.string=${KERNEL_NAME} ${SUBLEVEL} ${KERNEL_VARIANT} by ${KBUILD_BUILD_USER} for ${DEVICE_MODEL} (${DEVICE_CODENAME})/g" anykernel.sh
    else
      VARIANT="-no-KernelSU"
      print_info "Preparing standard variant..."
      sed -i "s/kernel.string=.*/kernel.string=${KERNEL_NAME} ${SUBLEVEL} ${KERNEL_VARIANT} by ${KBUILD_BUILD_USER} for ${DEVICE_MODEL} (${DEVICE_CODENAME})/g" anykernel.sh
    fi
    
    print_info "Creating zip file..."
    show_progress 3 "Compressing files"
    zip -r9 "${KERNEL_ZIP}${VARIANT}.zip" * -x .git README.md *placeholder
    
    print_info "Moving zip to home directory..."
    mv "${KERNEL_ZIP}${VARIANT}.zip" ~/
    print_success "Kernel package saved to ~/${KERNEL_ZIP}${VARIANT}.zip"
    
    cd ..
    sudo rm -rf ${AnyKernelPath}
    cleanup
}

# ═══════════════════════════════════════════════
# Cleanup function
# ═══════════════════════════════════════════════
function cleanup() {
    print_section "Cleanup"
    
    cd ${MainPath}
    if [ "$CLEANUP" = "yes" ]; then
      print_info "Cleaning up build files..."
      sudo rm -rf out/
      print_success "Cleanup completed"
    else
      print_info "Skipping cleanup as per configuration"
    fi
}

# ═══════════════════════════════════════════════
# Build time display function
# ═══════════════════════════════════════════════
function display_build_time() {
    hours=$((DIFF / 3600))
    minutes=$(((DIFF % 3600) / 60))
    seconds=$((DIFF % 60))
    
    print_build_success
}

# ═══════════════════════════════════════════════
# Main execution
# ═══════════════════════════════════════════════
print_header

START=$(date +"%s")

# Main process
getclang
updateclang
kernelsu
compile
zipping

# Calculate build time
END=$(date +"%s")
DIFF=$(($END - $START))
display_build_time

# Exit with success
exit 0

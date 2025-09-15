#!/usr/bin/env bash
# Copyright (c) 2021-2025 PeterSuh-Q3
# Author: PeterSuh-Q3
# License: MIT
# https://raw.githubusercontent.com/Umio-Yasuno/amdgpu_top/refs/heads/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
     _    __  __ ____   ____ ____  _   _   _____
    / \  |  \/  |  _ \ / ___|  _ \| | | | |_   _|___  _ __
   / _ \ | |\/| | | | | |  _| |_) | | | |   | |/ _ \| '_ \
  / ___ \| |  | | |_| | |_| |  __/| |_| |   | | (_) | |_) |
 /_/   \_\_|  |_|____/ \____|_|    \___/    |_|\___/| .__/
                                                    |_|
EOF
}

YW=$(echo "\033[33m")
BL=$(echo "\033[36m")
RD=$(echo "\033[01;31m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\r\033[K"
HOLD="-"
CM="${GN}✓${CL}"
silent() { "$@" >/dev/null 2>&1; }
set -e

set_package_manager() {
  PACKAGE_MANAGER="apt"
  PACKAGE_INSTALL="apt install -y"
  PACKAGE_REMOVE="apt remove --purge -y"
  PACKAGE_AUTOREMOVE="apt autoremove -y"
  LIBDRM_PKG="libdrm-dev"
  BUILD_ESSENTIAL="build-essential"
  LIBDRM_RUNTIME="libdrm-amdgpu1"
  
  if [ -f /etc/fedora-release ]; then
    PACKAGE_MANAGER="dnf"
    PACKAGE_INSTALL="dnf install -y"
    PACKAGE_REMOVE="dnf remove -y"
    PACKAGE_AUTOREMOVE=""
    LIBDRM_PKG="libdrm-devel"
    BUILD_ESSENTIAL="gcc gcc-c++ make cmake"
    LIBDRM_RUNTIME="libdrm"
  fi
}

header_info
echo "Loading..."

function msg_info() {
  local msg="$1"
  echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
  local msg="$1"
  echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

function msg_error() { echo -e "${RD}✗ $1${CL}"; }

check_system() {
  if [[ $EUID -ne 0 ]]; then
    msg_error "This script must be run as root"
    exit 1
  fi

  if [ "$PACKAGE_MANAGER" = "dnf" ]; then
    if ! rpm -q newt >/dev/null 2>&1; then
      msg_info "Installing whiptail dependency for Fedora"
      dnf install -y newt
      msg_ok "Installed whiptail dependency"
    fi
  fi
}

check_installed() {
  if command -v amdgpu_top &> /dev/null; then
    return 0
  else
    return 1
  fi
}

install() {
  header_info
  set_package_manager
  
  if check_installed; then
    while true; do
      read -p "amdgpu_top is already installed. Do you want to reinstall? (y/n)? " yn
      case $yn in
      [Yy]*) break ;;
      [Nn]*) exit ;;
      *) echo "Please answer yes or no." ;;
      esac
    done
  else
    while true; do
      read -p "Are you sure you want to install amdgpu_top? Proceed(y/n)? " yn
      case $yn in
      [Yy]*) break ;;
      [Nn]*) exit ;;
      *) echo "Please answer yes or no." ;;
      esac
    done
  fi
  
  read -r -p "Verbose mode? <y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] && STD="" || STD="silent"
  
  msg_info "Updating package lists and installing build dependencies"
  if [ "$PACKAGE_MANAGER" = "apt" ]; then
    $STD apt update
  fi
  $STD $PACKAGE_INSTALL $BUILD_ESSENTIAL git curl $LIBDRM_PKG $LIBDRM_RUNTIME
  msg_ok "Updated package lists and installed build dependencies"
  
  msg_info "Installing Rust via rustup official script"
  if command -v rustc &> /dev/null; then
    msg_ok "Rust is already installed, skipping installation"
  else
    export RUSTUP_INIT_SKIP_PATH_CHECK=yes
    if [[ "$STD" == "silent" ]]; then
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >/dev/null 2>&1
    else
      curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    source $HOME/.cargo/env
    msg_ok "Installed Rust"
  fi
  
  if ! source $HOME/.cargo/env 2>/dev/null; then
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
  
  msg_info "Installing amdgpu_top with cargo"
  $STD cargo install amdgpu_top
  
  msg_info "Installing amdgpu_top binary to /usr/sbin"
  cp -f $HOME/.cargo/bin/amdgpu_top /usr/sbin/
  msg_ok "Installed amdgpu_top binary"
  msg_ok "Completed Successfully!\n"
  
  echo -e "\n amdgpu_top has been installed and is available system-wide."
  echo -e " Run ${BL}amdgpu_top${CL} to start monitoring your AMD GPU.\n"
  echo
  echo -e " ${GN}Usage${CL}"
  echo -e " Run TUI mode "
  echo -e " ${BL}amdgpu_top${CL}"
  echo  
  echo -e " Run GUI mode "
  echo -e " ${RD}amdgpu_top --gui${CL}"
  echo  
  echo -e " Run SMI mode "
  echo -e " ${YW}amdgpu_top --smi${CL}"
}

uninstall() {
  header_info
  if ! check_installed; then
    msg_error "amdgpu_top is not installed on this system."
    exit 1
  fi
  
  while true; do
    read -p "Are you sure you want to uninstall amdgpu_top? (y/n)? " yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "Please answer yes or no." ;;
    esac
  done
  
  read -r -p "Also remove Rust and build dependencies? <y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] && REMOVE_DEPS=true || REMOVE_DEPS=false
  
  read -r -p "Verbose mode? <y/N> " prompt
  [[ ${prompt,,} =~ ^(y|yes)$ ]] && STD="" || STD="silent"
  
  msg_info "Removing amdgpu_top binary"
  rm -f /usr/sbin/amdgpu_top
  msg_ok "Removed amdgpu_top binary"
  
  if [ "$REMOVE_DEPS" = true ]; then
    msg_info "Removing Rust installation"
    if [ -f "$HOME/.cargo/env" ]; then
      source $HOME/.cargo/env
      if command -v rustup &> /dev/null; then
        $STD rustup self uninstall -y
      fi
    fi
    rm -rf $HOME/.cargo $HOME/.rustup
    msg_ok "Removed Rust installation"
    
    msg_info "Removing build dependencies"
    $STD $PACKAGE_REMOVE $BUILD_ESSENTIAL $LIBDRM_PKG $LIBDRM_RUNTIME
    if [ -n "$PACKAGE_AUTOREMOVE" ]; then
      $STD $PACKAGE_AUTOREMOVE
    fi
    msg_ok "Removed build dependencies"
  fi
  
  msg_ok "Completed Successfully!\n"
  echo -e "\n amdgpu_top has been successfully uninstalled from your system.\n"
}

header_info
check_system
OPTIONS=(Install "amdgpu_top AMD GPU monitoring tool"
  Uninstall "amdgpu_top from system")
CHOICE=$(whiptail --backtitle "AMD GPU Top Installation Script" --title "amdgpu_top" \
  --menu "Select an option:" 12 65 2 "${OPTIONS[@]}" 3>&1 1>&2 2>&3)
case $CHOICE in
"Install") install ;;
"Uninstall") uninstall ;;
*)
  echo "Exiting..."
  exit 0
  ;;
esac

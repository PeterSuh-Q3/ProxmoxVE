#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/PeterSuh-Q3/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: NVIDIA Driver Setup for Proxmox

function header_info {
clear
cat <<"EOF"

███╗   ██╗██╗   ██╗██╗██████╗ ██╗ █████╗ 
████╗  ██║██║   ██║██║██╔══██╗██║██╔══██╗
██╔██╗ ██║██║   ██║██║██║  ██║██║███████║
██║╚██╗██║╚██╗ ██╔╝██║██║  ██║██║██╔══██║
██║ ╚████║ ╚████╔╝ ██║██████╔╝██║██║  ██║
╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═╝

EOF
}

header_info
color
catch_errors

function update_script() {
  header_info
  if [[ ! -f /usr/bin/nvidia-smi ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating ${APP} Drivers"
  $STD apt-get update
  $STD apt-get -y upgrade
  msg_ok "Updated ${APP} Drivers"
  exit
}

function pre_reboot_setup() {
  header_info
  
  msg_info "Adding non-free repositories to sources.list"
  $STD sed -i '/^deb / {/non-free/! {/non-free-firmware/! s/$/ non-free non-free-firmware/}}' /etc/apt/sources.list
  msg_ok "Added non-free repositories"
  
  msg_info "Running apt update and full-upgrade"
  $STD apt-get update
  $STD apt-get full-upgrade -y
  msg_ok "System updated successfully"

  KERNEL_VERSION=$(uname -r)
  msg_info "Holding current proxmox kernel version: $KERNEL_VERSION"
  $STD apt-mark hold proxmox-kernel-$KERNEL_VERSION-signed
  msg_ok "Kernel version held"

  # /etc/modules에 모듈 추가
  for mod in nvidia nvidia_uvm nvidia_drm nvidia_modeset; do
    if ! grep -qx "$mod" /etc/modules; then
      msg_info "Adding $mod to /etc/modules"
      echo "$mod" >> /etc/modules
      msg_ok "Added $mod module"
    else
      msg_info "$mod already exists in /etc/modules"
    fi
  done

  msg_info "Checking for nouveau modules"
  NOUVEAU_COUNT=$(dmesg | grep nouveau | wc -l)
  
  if [ "$NOUVEAU_COUNT" -gt 0 ]; then
    msg_info "Detected nouveau module, applying blacklist"
    if ! grep -qx "blacklist nouveau" /etc/modprobe.d/blacklist-nvidia-nouveau.conf 2>/dev/null; then
      echo "blacklist nouveau" >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf
      msg_ok "Added 'blacklist nouveau'"
    fi
    if ! grep -qx "options nouveau modeset=0" /etc/modprobe.d/blacklist-nvidia-nouveau.conf 2>/dev/null; then
      echo "options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf
      msg_ok "Added 'options nouveau modeset=0'"
    fi
  else
    msg_info "No nouveau module detected, skipping blacklist"
  fi

  msg_info "Updating initramfs"
  $STD update-initramfs -u
  msg_ok "Initramfs updated"

  msg_info "Pre-reboot setup completed"
  msg_info "Reboot is required to unload nouveau and reload kernel modules"
  
  read -p "Do you want to reboot now? [y/N]: " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    msg_info "Rebooting system..."
    reboot
  else
    msg_info "Please reboot manually to complete the setup"
  fi
}

pre_reboot_setup

msg_ok "Pre-reboot setup completed successfully!\n"
echo -e "${CREATING}${GN}${APP} pre-setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Please reboot the system to continue with NVIDIA driver installation${CL}"

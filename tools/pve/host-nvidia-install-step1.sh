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

APP="Nvidia"

header_info
color
catch_errors

function readanswer() {
    while true; do
        read answ
        case $answ in
            [Yy]* ) answer="$answ"; break;;
            [Nn]* ) answer="$answ"; break;;
            * ) echo -e "${YW}Please answer yY/nN.${CL}";;
        esac
    done
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

  echo -e "${BFR} ${CM} ${GN}Pre-reboot setup completed${CL}"
  echo
  echo -e "${INFO} ${CM} ${YW}Reboot is required to unload nouveau and reload kernel modules${CL}"
  echo -e "${INFO} ${CM} ${YW}Do you want to reboot now? [Yy/Nn]: ${CL}"
  readanswer
  if [ -n "$answer" ] && [ "$answer" = "Y" ] || [ "$answer" = "y" ]; then
      echo -e "${BFR} ${CM} ${GN}Rebooting system...${CL}"
      sleep 2
      reboot
  else     
      echo -e "${BFR} ${CM} ${GN}Please reboot manually to complete the setup.${CL}"
  fi
  
}

pre_reboot_setup

echo -e "${INFO} ${CM} ${YW}Pre-reboot setup completed successfully!${CL}"
echo -e "${INFO} ${CM} ${YW}Please reboot the system to continue with NVIDIA driver installation${CL}"

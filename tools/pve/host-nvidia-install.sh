#!/bin/bash

# Color Palette
G='\033[1;32m'
R='\033[0;31m'
B='\033[0;34m'
Y='\033[0;33m'
N='\033[0m'

# --- Helper Functions ---

# Display a message with a color
msg() {
    local text="$1"
    local color="$2"
    echo -e "${color}${text}${N}"
}

FLAG_FILE="/root/.nvidia_setup_postreboot"

if [ ! -f "$FLAG_FILE" ]; then
  #### 1차 처리(재부팅 전) ####
  msg "[INFO][PRE-REBOOT] Running apt update and full-upgrade" "$G"
  apt-get update && apt-get full-upgrade -y >/dev/null
  
  KERNEL_VERSION=$(uname -r)
  echo
  msg "[INFO][PRE-REBOOT] Holding current proxmox kernel version: $KERNEL_VERSION" "$G"
  apt-mark hold proxmox-kernel-$KERNEL_VERSION-signed

  # /etc/modules 중복 없이 모듈명 추가
  for mod in nvidia nvidia_uvm nvidia_drm nvidia_modeset; do
    if ! grep -qx "$mod" /etc/modules; then
      msg "[INFO][PRE-REBOOT] Adding $mod to /etc/modules" "$G"
      echo "$mod" >> /etc/modules
    else
      msg "[INFO][PRE-REBOOT] $mod already exists in /etc/modules" "$R"
    fi
  done

  echo
  msg "[INFO][PRE-REBOOT] Checking loaded nouveau modules" "$Y"
  NOUVEAU_COUNT=$(dmesg | grep nouveau | wc -l)
  msg "[INFO][PRE-REBOOT] dmesg | grep nouveau | wc -l = $NOUVEAU_COUNT" "$G"

  echo
  if [ "$NOUVEAU_COUNT" -gt 0 ]; then
    echo "[INFO][PRE-REBOOT] Detected nouveau module, applying blacklist"
    if ! grep -qx "blacklist nouveau" /etc/modprobe.d/blacklist-nvidia-nouveau.conf 2>/dev/null; then
      echo "blacklist nouveau" >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf
      msg "[INFO][PRE-REBOOT] Added 'blacklist nouveau'" "$G"
    else
      msg "[INFO][PRE-REBOOT] 'blacklist nouveau' already exists" "$R"
    fi
    if ! grep -qx "options nouveau modeset=0" /etc/modprobe.d/blacklist-nvidia-nouveau.conf 2>/dev/null; then
      echo "options nouveau modeset=0" >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf
      msg "[INFO][PRE-REBOOT] Added 'options nouveau modeset=0'" "$G"
    else
      msg "[INFO][PRE-REBOOT] 'options nouveau modeset=0' already exists" "$R"
    fi
  else
    msg "[INFO][PRE-REBOOT] No nouveau module detected, skipping blacklist." "$Y"
  fi

  msg "[INFO][PRE-REBOOT] Updating initramfs" "$G"
  update-initramfs -u

  #### 플래그 파일 제작 ####
  touch "$FLAG_FILE"
  msg "[INFO][PRE-REBOOT] Scheduling post-reboot script" "$B"
  echo "@reboot root bash $0" > /etc/cron.d/nvidia_setup

  msg "[INFO][PRE-REBOOT] Reboot is required to unload nouveau and reload kernel modules" "$Y"
  reboot

  exit 0
fi

#### 2차 처리(재부팅 후) ####
msg "[INFO][POST-REBOOT] After reboot, install necessary kernel headers" "$G"
apt-get update && apt-get install -y pve-headers-$(uname -r)

msg "[INFO][POST-REBOOT] Installing nvidia-driver package" "$G"
apt-get install -y nvidia-driver >/dev/null

msg "[INFO][POST-REBOOT] Checking NVIDIA driver status with nvidia-smi" "$B"
nvidia-smi

# cleanup
rm -f "$FLAG_FILE"
rm -f /etc/cron.d/nvidia_setup
msg "[INFO][POST-REBOOT] NVIDIA driver setup complete and cleanup done." "$Y"

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

#### 2차 처리(재부팅 후) ####
msg "[INFO][POST-REBOOT] After reboot, install necessary kernel headers" "$G"
apt-get update && apt-get install -y pve-headers-$(uname -r)

msg "[INFO][POST-REBOOT] Installing nvidia-driver package" "$G"
apt-get install -y nvidia-driver >/dev/null

msg "[INFO][POST-REBOOT] Checking NVIDIA driver status with nvidia-smi" "$B"
nvidia-smi

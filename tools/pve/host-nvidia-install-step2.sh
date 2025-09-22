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
msg_info "Installing necessary kernel headers"
$STD apt-get update 
$STD apt-get install -y pve-headers-$(uname -r)
msg_ok "Installed kernel headers"

msg_info "Installing nvidia-driver package"
$STD apt-get install -y nvidia-driver >/dev/null
msg_ok "Installed nvidia-driver package"

nvidia-modprobe -u -c=0
msg_ok "Checking NVIDIA driver status with nvidia-smi"
nvidia-smi

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

SERVICE_NAME=myscript.service
SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"

msg_info "Creating systemd service file at ${SERVICE_PATH}..."

cat <<EOF > "${SERVICE_PATH}"
[Unit]
Description=Custom Startup Script
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/nvidia-modprobe -u -c=0

[Install]
WantedBy=multi-user.target
EOF

msg_ok "${SERVICE_PATH} Service file created."

msg_info "Enabling ${SERVICE_NAME} to start on boot..."
systemctl enable "${SERVICE_NAME}"
msg_ok "Service enabled to start on boot."

msg_ok "Checking NVIDIA driver status with nvidia-smi"
nvidia-smi

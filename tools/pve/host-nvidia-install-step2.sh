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

#### 2차 처리(재부팅 후) ####
msg "[INFO][POST-REBOOT] After reboot, install necessary kernel headers" "$G"
apt-get update && apt-get install -y pve-headers-$(uname -r)

msg "[INFO][POST-REBOOT] Installing nvidia-driver package" "$G"
apt-get install -y nvidia-driver >/dev/null

msg "[INFO][POST-REBOOT] Checking NVIDIA driver status with nvidia-smi" "$B"
nvidia-smi

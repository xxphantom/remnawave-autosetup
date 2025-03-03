#!/bin/bash
echo "Downloading and preparing Remnawave installer..."
wget -O install_temp.sh https://raw.githubusercontent.com/xxphantom/remnawave-autosetup/refs/heads/main/install_remnawave.sh
sed -i 's/\r$//' install_temp.sh
mv install_temp.sh install_remnawave.sh
chmod +x install_remnawave.sh
./install_remnawave.sh

# Delete installation scripts after completion
rm -f install_remnawave.sh
rm -f "$0"  # Delete this script itself

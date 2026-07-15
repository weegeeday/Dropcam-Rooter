#!/bin/bash
set -e

echo "============================================="
echo "  Dropcam A5s 'Coconut' Rooted Toolkit       "
echo "============================================="

# 1. Choose connection method
echo "How is the camera connected?"
echo "  1) Over USB cable (Static IP: 192.168.75.2)"
echo "  2) Over Wi-Fi (Custom IP)"
read -p "Select option [1/2]: " CONN_OPTION

if [ "$CONN_OPTION" = "1" ]; then
    CAMERA_IP="192.168.75.2"
    echo "[+] USB mode selected. Checking host network interface..."
    
    USB_IFACE=""
    # Find active USB Ethernet adapter
    USB_IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -E "^usb|^enp|^enx" | head -n 1) || true
    if [ -z "$USB_IFACE" ]; then
        echo "[!] Warning: No USB Ethernet interface detected. Please make sure the USB cable is connected."
        read -p "Enter interface name manually (e.g. usb0): " USB_IFACE
    fi

    # Find and remove conflicting IP from any other interface (due to random MAC on reboot)
    CONFLICT_IFACE=$(ip -o addr show | grep "192.168.75.1" | awk '{print $2}')
    if [ -n "$CONFLICT_IFACE" ] && [ "$CONFLICT_IFACE" != "$USB_IFACE" ]; then
        echo "[+] Removing conflicting IP 192.168.75.1 from old interface $CONFLICT_IFACE..."
        sudo ip addr del 192.168.75.1/24 dev "$CONFLICT_IFACE" || true
    fi

    # Disable NetworkManager on this interface to prevent DHCP overrides
    if command -v nmcli &> /dev/null; then
        echo "[+] Disabling NetworkManager control on interface $USB_IFACE..."
        sudo nmcli device set "$USB_IFACE" managed no || true
    fi

    # Check if active interface already has this IP assigned
    if ! ip -o addr show dev "$USB_IFACE" | grep -q "192.168.75.1"; then
        echo "[+] Configuring host IP 192.168.75.1 on interface $USB_IFACE (requires sudo)..."
        sudo ip addr add 192.168.75.1/24 dev "$USB_IFACE"
    else
        echo "  [✓] Host IP 192.168.75.1 is already configured on interface $USB_IFACE."
    fi
    sudo ip link set "$USB_IFACE" up || true
else
    read -p "Enter camera's Wi-Fi IP address (e.g. 192.168.1.130): " CAMERA_IP
fi

# 2. Verify connection via ping
echo "[+] Verifying connection to camera at $CAMERA_IP..."
if ! ping -c 1 -W 2 "$CAMERA_IP" &> /dev/null; then
    echo "[!] Error: Camera at $CAMERA_IP is unreachable."
    echo "    Please check physical connections or IP configurations."
    exit 1
fi
echo "  [✓] Camera is online!"

# 3. Toolkit menu
echo ""
echo "=== Actions ==="
echo "  1) Open interactive shell (Telnet/SSH)"
echo "  2) Edit Wi-Fi credentials"
echo "  3) Update boot script (ie_auto.sh)"
read -p "Choose action [1/3]: " ACTION_OPTION

if [ "$ACTION_OPTION" = "1" ]; then
    echo "[+] Attempting SSH connection first..."
    if ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no root@"$CAMERA_IP" 2>/dev/null; then
        echo "[✓] SSH session closed."
    else
        echo "[!] SSH failed or not configured yet. Falling back to Telnet..."
        telnet "$CAMERA_IP" || true
    fi
elif [ "$ACTION_OPTION" = "2" ]; then
    read -p "Enter new Wi-Fi SSID: " NEW_SSID
    read -p "Enter new Wi-Fi Password: " NEW_PASS

    echo "[+] Writing new Wi-Fi profile to camera..."
    # Generate remote commands
    (
      sleep 1
      echo "cat << 'EOF' > /mnt/dropcam/wpa_supplicant.conf"
      echo "ctrl_interface=/var/run/wpa_supplicant"
      echo "update_config=1"
      echo ""
      echo "network={"
      echo "	ssid=\"$NEW_SSID\""
      echo "	psk=\"$NEW_PASS\""
      echo "	key_mgmt=WPA-PSK"
      echo "}"
      echo "EOF"
      sleep 1
      echo "echo '=== Configuration saved! ==='"
      echo "exit"
    ) | telnet "$CAMERA_IP" || true

    echo "[✓] Wi-Fi credentials updated successfully!"
    echo "    Reboot the camera to connect to the new network."
elif [ "$ACTION_OPTION" = "3" ]; then
    if [ ! -f "ie_auto.sh" ]; then
        echo "[!] Error: 'ie_auto.sh' not found in current directory."
        exit 1
    fi
    
    # Determine host IP based on connection method
    if [ "$CONN_OPTION" = "1" ]; then
        HOST_IP="192.168.75.1"
    else
        # Find host IP associated with the routing interface to the camera
        HOST_IP=$(ip route get "$CAMERA_IP" | grep -oP 'src \K\S+')
    fi

    echo "[+] Starting local sender port on host..."
    # Listen on port 1234 and send ie_auto.sh when camera connects
    nc -l -p 1234 < ie_auto.sh &
    NC_PID=$!
    
    echo "[+] Transferring ie_auto.sh to camera..."
    (
      sleep 1
      echo "nc $HOST_IP 1234 > /mnt/dropcam/ie_auto.sh"
      sleep 2
      echo "chmod +x /mnt/dropcam/ie_auto.sh"
      sleep 1
      echo "echo '=== ie_auto.sh updated! ==='"
      echo "exit"
    ) | telnet "$CAMERA_IP" || true
    
    # Wait for host sender to complete
    wait $NC_PID
    echo "[✓] Boot script updated successfully!"
else
    echo "[!] Invalid action selected."
fi

#!/bin/bash
set -e

echo "============================================="
echo "  Dropcam A5s 'Coconut' USB Rooting Utility  "
echo "============================================="

# 1. Ask user for Wi-Fi credentials
read -p "Enter your Wi-Fi SSID: " WIFI_SSID
read -p "Enter your Wi-Fi Password: " WIFI_PASS

# Determine workspace directories
WORKSPACE_DIR="workspace/adc_extracted"
OUTPUT_DIR="workspace/output"

# Determine path context
if [ -f "../gpboot.c" ]; then
    PARENT_DIR=".."
else
    PARENT_DIR="gopro-usb-tools"
fi

# 2. Boot the camera into RAM first to access the storage
echo ""
echo "=== Step 1: Boot Camera into RAM ==="
echo "Choose an option:"
echo "  1) Boot camera into RAM via USB bootloader (Default)"
echo "  2) Skip bootloader (Camera is already booted in RAM, connect directly)"
read -p "Select option [1/2]: " BOOT_OPTION

if [ "$BOOT_OPTION" != "2" ]; then
    while true; do
        echo "1. Connect your Dropcam via USB in Bootloader Mode."
        read -p "   Press Enter once connected to start booting..."
        echo "[+] Booting temporary Linux kernel into RAM..."
        
        BOOT_SUCCESS=0
        if [ -f "../gpboot.c" ]; then
            (cd .. && sudo ./gpboot --linux) && BOOT_SUCCESS=1 || BOOT_SUCCESS=0
        else
            (cd gopro-usb-tools && sudo ./gpboot --linux) && BOOT_SUCCESS=1 || BOOT_SUCCESS=0
        fi

        if [ $BOOT_SUCCESS -eq 1 ]; then
            echo "  [✓] Camera booted successfully!"
            break
        fi

        echo ""
        echo "[!] Error: Failed to boot camera (USB device not found or permission issue)."
        read -p "Would you like to try again? [y/n]: " TRY_AGAIN
        if [ "$TRY_AGAIN" != "y" ] && [ "$TRY_AGAIN" != "Y" ]; then
            echo "Exiting."
            exit 1
        fi
    done
else
    echo "[+] Skipping bootloader, attempting to connect directly..."
fi

echo "[+] Waiting for virtual Ethernet interface to initialize on host..."
USB_IFACE=""
MAX_RETRIES=30
for ((i=1; i<=MAX_RETRIES; i++)); do
    # Search for network interfaces matching usb or enp... (excluding loopback)
    USB_IFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -E "^usb|^enp|^enx" | head -n 1) || true
    if [ -n "$USB_IFACE" ]; then
        echo "  [✓] Detected USB Ethernet interface: $USB_IFACE"
        break
    fi
    sleep 1
done

if [ -z "$USB_IFACE" ]; then
    echo "[!] Error: Could not detect any USB network interface after 30 seconds."
    echo "    Please verify connections, or manually set your IP to 10.9.9.2/24."
    exit 1
fi

# Configure host IP
# Find and remove conflicting IP from any other interface (due to random MAC on reboot)
CONFLICT_IFACE=$(ip -o addr show | grep "10.9.9.2" | awk '{print $2}')
if [ -n "$CONFLICT_IFACE" ] && [ "$CONFLICT_IFACE" != "$USB_IFACE" ]; then
    echo "[+] Removing conflicting IP 10.9.9.2 from old interface $CONFLICT_IFACE..."
    sudo ip addr del 10.9.9.2/24 dev "$CONFLICT_IFACE" || true
fi
# Disable NetworkManager on this interface to prevent DHCP overrides
if command -v nmcli &> /dev/null; then
    echo "[+] Disabling NetworkManager control on interface $USB_IFACE..."
    sudo nmcli device set "$USB_IFACE" managed no || true
fi
# Check if active interface already has this IP assigned
if ! ip -o addr show dev "$USB_IFACE" | grep -q "10.9.9.2"; then
    echo "[+] Configuring host IP 10.9.9.2 on interface $USB_IFACE (requires sudo)..."
    sudo ip addr add 10.9.9.2/24 dev "$USB_IFACE"
else
    echo "  [✓] Host IP 10.9.9.2 is already configured on interface $USB_IFACE."
fi
sudo ip link set "$USB_IFACE" up || true

# Wait until the camera (10.9.9.1) is pingable
echo "[+] Waiting for camera at 10.9.9.1 to respond to ping..."
PING_RETRIES=20
PING_SUCCESS=0
for ((i=1; i<=PING_RETRIES; i++)); do
    if ping -c 1 -W 1 10.9.9.1 &> /dev/null; then
        echo "  [✓] Camera is online and pingable!"
        PING_SUCCESS=1
        break
    fi
    echo "  ... waiting for link (attempt $i/$PING_RETRIES)"
    sleep 1
done

if [ $PING_SUCCESS -eq 0 ]; then
    echo "[!] Error: Camera at 10.9.9.1 is unreachable."
    echo "    Please verify the network settings on interface $USB_IFACE."
    exit 1
fi

# 3. Pull the stock configuration partition automatically from the camera
echo "[+] Starting local receiver port on host..."
# Start listener on host in background
nc -l -p 1234 > "$PARENT_DIR/adc_stock.bin" &
NC_PID=$!

echo "[+] Initializing NAND driver and dumping stock configuration partition from camera..."
(
  sleep 1
  echo "echo ambarella-nand > /sys/bus/platform/drivers/ambarella-nand/bind"
  sleep 2
  echo "dd if=/dev/mtd9 bs=4096 | nc 10.9.9.2 1234"
  sleep 2
  echo "exit"
) | telnet 10.9.9.1 || true

# Wait for the transfer process to complete
wait $NC_PID
echo "  [✓] Configuration partition successfully dumped to host."

# 4. Extract configuration partition template
echo "[+] Extracting stock configuration partition template..."
# Jeffersons JFFS2 extraction tool must be installed via pip
if ! command -v jefferson &> /dev/null; then
    echo "    Installing jefferson parser via pip..."
    pip3 install --user jefferson
fi
rm -rf "$WORKSPACE_DIR"
~/.local/bin/jefferson -d "$WORKSPACE_DIR" "$PARENT_DIR/adc_stock.bin"

# 5. Create modified wpa_supplicant.conf
echo "[+] Configuring Wi-Fi profile..."
cat << EOF > "$WORKSPACE_DIR/wpa_supplicant.conf"
ctrl_interface=/var/run/wpa_supplicant
update_config=1

network={
	ssid="$WIFI_SSID"
	psk="$WIFI_PASS"
	key_mgmt=WPA-PSK
}
EOF

# 6. Create passwordless shadow file
echo "[+] Clearing root password..."
cat << EOF > "$WORKSPACE_DIR/shadow"
root::10933:0:99999:7:::
bin:*:10933:0:99999:7:::
daemon:*:10933:0:99999:7:::
adm:*:10933:0:99999:7:::
lp:*:10933:0:99999:7:::
sync:*:10933:0:99999:7:::
shutdown:*:10933:0:99999:7:::
halt:*:10933:0:99999:7:::
uucp:*:10933:0:99999:7:::
operator:*:10933:0:99999:7:::
nobody:*:10933:0:99999:7:::
default::10933:0:99999:7:::
EOF

# 7. Copy the ie_auto.sh bootloader hook script
echo "[+] Injecting integration engineering execution hook (ie_auto.sh)..."
cp ie_auto.sh "$WORKSPACE_DIR/ie_auto.sh"
chmod +x "$WORKSPACE_DIR/ie_auto.sh"

# 8. Compile the JFFS2 partition image
echo "[+] Compiling new JFFS2 image..."
mkfs.jffs2 -d "$WORKSPACE_DIR" -o "$OUTPUT_DIR/adc_new.bin" -e 0x20000 --pad=3145728 -l
echo "  [✓] Image compiled successfully at: $OUTPUT_DIR/adc_new.bin"

# 9. Transfer the modified configuration back to the camera
echo "[+] Starting local sender port on host..."
# Start sender listener on host in background
nc -l -p 1234 < "$OUTPUT_DIR/adc_new.bin" &
NC_PID=$!

echo "[+] Transferring configuration image to camera..."
(
  sleep 1
  echo "nc 10.9.9.2 1234 > /tmp/adc_new.bin"
  sleep 2
  echo "exit"
) | telnet 10.9.9.1 || true

# Wait for the transfer to complete
wait $NC_PID
echo "  [✓] Image successfully transferred to camera (/tmp/adc_new.bin)."

# 10. Erase and write flash on the Dropcam
echo "[+] Executing flash update on Dropcam..."
(
  sleep 1
  echo "/usr/sbin/flash_eraseall /dev/mtd9"
  sleep 2
  echo "/usr/sbin/nandwrite -p /dev/mtd9 /tmp/adc_new.bin"
  sleep 2
  echo "echo '=== Flashing Complete! Reboot the camera now. ==='"
  sleep 1
  echo "exit"
) | telnet 10.9.9.1 || true

echo ""
echo "[✓] Flashing process complete!"
echo "    Please unplug the camera and plug it back in to boot normally."
echo "    The camera will be accessible on your local network at port 23 (Telnet)."


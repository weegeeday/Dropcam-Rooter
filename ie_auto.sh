#!/bin/sh

# Start telnetd on standard port with shell login
/usr/sbin/telnetd -l /bin/sh &

# Generate SSH host key if it doesn't exist, then start dropbear
if [ ! -f /mnt/dropcam/dropbear_host_key ]; then
  /bin/dropbearkey -t rsa -f /mnt/dropcam/dropbear_host_key
fi
/sbin/dropbear -B -r /mnt/dropcam/dropbear_host_key

# Enable USB Ethernet interface for local diagnostics over USB cable
modprobe g_ether
ifconfig usb0 192.168.75.2 up

# Create a dummy connect script that sleeps forever to avoid CPU load
cat << 'EOF' > /tmp/dummy_connect
#!/bin/sh
while true; do
  sleep 3600
done
EOF
chmod +x /tmp/dummy_connect

# Bind-mount the dummy script over the stock Nest connect client
mount -o bind /tmp/dummy_connect /usr/bin/connect

# Locate and wrap wpa_supplicant to strip the blocking -W flag dynamically on boot
if [ -f /sbin/wpa_supplicant ]; then
  WPA_PATH="/sbin/wpa_supplicant"
elif [ -f /usr/sbin/wpa_supplicant ]; then
  WPA_PATH="/usr/sbin/wpa_supplicant"
else
  WPA_PATH="/usr/bin/wpa_supplicant"
fi

cp "$WPA_PATH" /tmp/wpa_supplicant_real
cat << 'EOF' > /tmp/wpa_supplicant_wrapper
#!/bin/sh
ARGS=""
for arg in "$@"; do
  if [ "$arg" != "-W" ]; then
    ARGS="$ARGS \"$arg\""
  fi
done
eval "/tmp/wpa_supplicant_real $ARGS"
EOF
chmod +x /tmp/wpa_supplicant_wrapper

# Bind-mount our wrapper over the system binary path
mount -o bind /tmp/wpa_supplicant_wrapper "$WPA_PATH"

# Run all blocking operations and loops in the background so bootstrap.sh doesn't hang
(
  # Wait for the wlan0 interface to appear
  while [ ! -e /sys/class/net/wlan0 ]; do
    sleep 0.5
  done

  # Disable Wi-Fi power saving mode
  iw dev wlan0 set power_save off

  # Start wpa_supplicant manually since we neutered connect and a5s_boot.sh
  wpa_supplicant -iwlan0 -c/mnt/dropcam/wpa_supplicant.conf -Dnl80211 -B

  # Request IP via DHCP once wpa_supplicant connects
  udhcpc -i wlan0 -b -R

  # Feed watchdog in a loop to keep the device alive
  while true; do
    echo '0' > /dev/watchdog
    sleep 10
  done
) &

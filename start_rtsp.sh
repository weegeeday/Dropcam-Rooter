#!/bin/sh
#
# Ambarella A5s RTSP Streaming Initialization Script
# Run this script directly on the Dropcam to start the local RTSP video stream.
#

# 1. Determine camera hardware version and image sensor
HWVER=1
if [ -f /mnt/dropcam/hwver ]; then
    HWVER=$(cat /mnt/dropcam/hwver)
fi

if [ "$HWVER" = "1" ] || [ "$HWVER" = "2" ]; then
    SENSOR="ov9710"
    echo "[+] Hardware Profile: Dropcam HD (Version $HWVER) -> Sensor: $SENSOR (720p)"
else
    SENSOR="ar0330"
    echo "[+] Hardware Profile: Dropcam Pro (Version $HWVER) -> Sensor: $SENSOR (1080p)"
fi

# 2. Load sensor drivers and load DSP microcode
echo "[+] Initializing Ambarella IAV subsystem and loading $SENSOR driver..."
/usr/local/bin/init.sh --$SENSOR

# 3. Generate Wi-Fi optimized 720p VBR encoder config if missing
if [ ! -f /mnt/dropcam/encode.cfg ]; then
    echo "[+] Writing optimized VBR encoder config to /mnt/dropcam/encode.cfg..."
    cat << 'EOF' > /mnt/dropcam/encode.cfg
vin_mode		= 65524
vin_framerate	= 17083750
vout_type		= 1
vout_mode		= 65520
vin_mirror		= 0
vin_bayer		= 1

# Stream 0 Settings (720p High Definition - VBR with 1.5 Mbps max limit)
s0_type		= 1
s0_width		= 1280
s0_height		= 720
s0_brc			= 1
s0_vbr_min_bps	= 500000
s0_vbr_max_bps	= 1500000
s0_N			= 30
s0_start		= 1

s1_type		= 0
s2_type		= 0
s3_type		= 0
EOF
fi

# 4. Terminate any running encoder/RTSP server processes
echo "[+] Cleaning up existing server instances..."
killall -9 rtsp_server mediaserver image_server 2>/dev/null
sleep 1

# 5. Start the local media encoder & RTSP server
echo "[+] Starting mediaserver and H.264 RTSP server..."
/usr/local/bin/mediaserver -a -f /mnt/dropcam/encode.cfg &

echo "[✓] Setup complete! You can play this stream at:"
# Get IP address of wlan0
WLAN0_IP=$(ifconfig wlan0 | grep 'inet addr' | awk -F: '{print $2}' | awk '{print $1}')
if [ -n "$WLAN0_IP" ]; then
    echo "    rtsp://$WLAN0_IP/stream1"
else
    echo "    rtsp://<camera_wifi_ip>/stream1"
fi

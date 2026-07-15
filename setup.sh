#!/bin/bash
set -e

echo "=== Dropcam A5s Rooting Toolchain: Setup Environment ==="

# 1. Install host package dependencies
echo "[+] Installing system dependencies (mtd-utils, libusb, netcat, wget, git, make, gcc)..."
if [ -f /usr/bin/apt-get ]; then
    echo "    Detected Debian/Ubuntu/Pop!_OS system. Please enter sudo password if prompted."
    sudo apt-get update && sudo apt-get install -y mtd-utils libusb-1.0-0-dev netcat-openbsd wget git make gcc
elif [ -f /usr/bin/dnf ]; then
    echo "    Detected Fedora system. Please enter sudo password if prompted."
    sudo dnf install -y mtd-utils libusb1-devel netcat wget git make gcc
else
    echo "[!] Unknown package manager. Please ensure 'mtd-utils', 'libusb-1.0-dev', 'netcat', 'wget', 'git', 'make', and 'gcc' are installed manually."
fi

# 2. Check and clone gopro-usb-tools if not already in a clone
if [ ! -f "../gpboot.c" ]; then
    echo "[+] Cloning gopro-usb-tools repository..."
    if [ ! -d "gopro-usb-tools" ]; then
        git clone https://github.com/evilwombat/gopro-usb-tools.git gopro-usb-tools
    fi
    PARENT_DIR="gopro-usb-tools"
else
    PARENT_DIR=".."
fi

# 3. Build the gpboot and prepare-bootstrap binaries
echo "[+] Building gopro-usb-tools compilation targets..."
make -C "$PARENT_DIR"

# 4. Extract bootstrap files from user-supplied firmware
if [ ! -f "$PARENT_DIR/v312-bld.bin" ] || [ ! -f "$PARENT_DIR/v312-hal-reloc.bin" ]; then
    if [ ! -f "$PARENT_DIR/HD2-firmware.bin" ]; then
        echo ""
        echo "[!] Error: 'HD2-firmware.bin' is missing."
        echo "    Due to copyright restrictions, you must manually download the GoPro HD2 v312 firmware file"
        echo "    (HD2-firmware.bin) and place it in the '$PARENT_DIR/' directory."
        echo "    You can typically locate this file via web search engines or firmware archives."
        exit 1
    fi
    echo "[+] Running prepare-bootstrap to extract v312-bld.bin and v312-hal-reloc.bin..."
    (cd "$PARENT_DIR" && ./prepare-bootstrap HD2-firmware.bin)
fi

# 5. Check for Linux kernel and ramdisk
REQUIRED_FILES=(
    "$PARENT_DIR/gpboot"
    "$PARENT_DIR/zImage"
    "$PARENT_DIR/initrd.lzma"
    "$PARENT_DIR/v312-bld.bin"
    "$PARENT_DIR/v312-hal-reloc.bin"
)

MISSING=0
for FILE in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$FILE" ]; then
        echo "  [x] Missing required file: $FILE"
        MISSING=1
    else
        echo "  [✓] Found: $FILE"
    fi
done

if [ $MISSING -eq 1 ]; then
    echo ""
    echo "[!] Critical boot components are missing."
    echo "    Please verify that 'zImage' and 'initrd.lzma' are placed"
    echo "    in the '$PARENT_DIR' folder."
    exit 1
fi

# 6. Create working directory structure
echo "[+] Creating output and workspace folders..."
mkdir -p workspace/adc_extracted
mkdir -p workspace/output

echo "[✓] Environment successfully prepared!"
echo "    You can now run './root_camera.sh' to begin rooting."


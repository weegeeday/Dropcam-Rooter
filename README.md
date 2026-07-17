# Dropcam A5s "Coconut" Local Rooting Toolchain

This repository contains scripts and utilities to permanently root, jailbreak, and manage legacy Ambarella A5s-based Dropcam devices (such as the Dropcam 2013) over USB without soldering. 

This is achieved by booting a temporary Linux kernel into RAM to dump the writeable configuration partition, patching it to include custom startup hooks (`ie_auto.sh`), and flashing it back.

If you're looking for software to use your dropcam after its been rooted, check out [droprcam](https://github.com/weegeeday/Droprcam). Turns it into a regular ip camera.

## Repository Contents

*   **setup.sh**: Host setup script. Resolves compiler and library dependencies, clones the underlying boot toolchain, and prepares the bootstrap files.
*   **root_camera.sh**: The automated jailbreak utility. Walks you through booting, dumping the stock configuration, patching the filesystem, and flashing the update.
*   **rooted_toolkit.sh**: Post-jailbreak management script. Used to open shells, modify Wi-Fi credentials, or push boot script updates to already rooted cameras.
*   **ie_auto.sh**: The custom startup script template injected into the camera's configuration partition.
*   **HOWTO.md**: Step-by-step instructions for physical preparation, booting, and flashing the camera.
*   **wiki/**: Directory containing in-depth architectural details, FAQs, and troubleshooting documentation.

## Requirements

### Host System
*   A Linux host system (Debian, Ubuntu, Pop!_OS, or Fedora are supported out of the box).
*   A functional compiler and standard build tools (`gcc`, `make`, `git`).
*   Network management tools (`iproute2`, `netcat`, `ping`).
*   Python 3 and `pip` (to install the `jefferson` JFFS2 filesystem extractor).

### Target Hardware
*   An Ambarella A5s-based Dropcam (e.g., Dropcam 2013).
*   A Micro-USB cable connected directly to the host PC.
*   Physical access to the camera's bootloader button.

## Documentation Quick Links

*   For physical preparation and step-by-step jailbreaking instructions, see [HOWTO.md](HOWTO.md).
*   For questions regarding hardware support, RTSP, and offline behavior, see [wiki/FAQ.md](wiki/FAQ.md).
*   For interface problems, connection dropouts, or driver binding errors, see [wiki/Troubleshooting.md](wiki/Troubleshooting.md).
*   For details on the jailbreak mechanics and firmware layouts, see [wiki/Jailbreak-Mechanics.md](wiki/Jailbreak-Mechanics.md).

## Credits and Special Thanks

*   **evilwombat**: Author of [gopro-usb-tools](https://github.com/evilwombat/gopro-usb-tools), providing the critical bootloader capabilities, RAM bootstrap files, and USB memory loader interface.
*   **Kris Brosch (Include Security)**: For the pioneering hardware reverse-engineering research and documentation on the Dropcam's board layout, boot behavior, and serial command interface, which provided the foundational architecture knowledge for this project. Detailed in their [Include Security Blog Post](https://blog.includesecurity.com/2014/04/reversing-the-dropcam-part-2-rooting-your-dropcam/).
*   **Gemini**: Doing so much of the work, and helping out. 

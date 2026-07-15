# Dropcam Rootkit Wiki

Welcome to the Dropcam root documentation wiki. This section provides in-depth technical references for developers and users interested in customizing or understanding the jailbreak.

## Sections

*   [Jailbreak Mechanics](Jailbreak-Mechanics.md): Detailed information on how the exploit works, partition structures, and system execution hooks.
*   [Troubleshooting](Troubleshooting.md): Workarounds for common errors like network conflicts, missing USB permissions, and interface name fluctuations.
*   [FAQ](FAQ.md): Frequently asked questions about firmware modifications, RTSP streaming, and offline operations.

## Hardware Reference

*   **SoC:** Ambarella A5s (ARM1136J-S processor running at up to 528 MHz, ARMv6 architecture).
*   **Memory:** 256MB DDR2 SDRAM.
*   **NAND Storage:** Samsung 256MB SLC NAND flash (2Gb memory chip).

### Hardware Version 1 & 2 (Dropcam HD)
*   **Wi-Fi:** Atheros AR6003 SDIO dual-band (using the `ath6kl_sdio` kernel module).
*   **Audio Codec:** AKM AK4642.
*   **Image Sensor:** OmniVision OV9710 (1MP, native 1280x720 720p).
*   **LED Status Pins:** Yellow (GPIO 88), Blue (GPIO 89), Red (GPIO 90).

### Hardware Version 3, 4 & 5 (Dropcam Pro)
*   **Wi-Fi:** Atheros AR6233 SDIO dual-band.
*   **Audio Codec:** Wolfson WM8974.
*   **Image Sensor:** Aptina AR0330 (3.1MP, native 1920x1080 1080p).
*   **LED Status Pins:** Yellow (GPIO 45), Blue (GPIO 46), Red (GPIO 90).

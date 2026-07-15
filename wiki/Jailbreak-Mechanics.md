# Jailbreak Mechanics

This page explains the software layout of the Dropcam firmware and the mechanical execution of the jailbreak.

---

## 1. NAND Flash Partition Layout

The camera's internal NAND storage is split into several partitions managed via standard Memory Technology Devices (MTD):

*   **mtd0 (bst):** Bootstrap loader (Amboot).
*   **mtd1 (ptb):** Partition table metadata.
*   **mtd2 (bld):** Bootloader.
*   **mtd3 (hal):** Hardware abstraction layer library.
*   **mtd4 (pri):** Primary boot partition (unused in stock offline mode).
*   **mtd5 (sec):** Secondary boot partition (unused in stock offline mode).
*   **mtd6 (bak):** Active root filesystem. Formatted as UBI (UBIFS).
*   **mtd7 (dsp):** Digital Signal Processor (DSP) microcode.
*   **mtd8 (lnx):** Update partition (empty by default).
*   **mtd9 (adc):** Configuration filesystem. Formatted as JFFS2 and mounted at `/mnt/dropcam` (read-write).

---

## 2. Exploiting the Integration Hook

At boot, the standard root filesystem `/etc/inittab` executes the main system configuration manager `/usr/bin/bootstrap.sh`. 

Inside `bootstrap.sh` (lines 22-24), there is a built-in Hook check:
```bash
if [ -f /mnt/dropcam/ie_auto.sh ]; then
  /mnt/dropcam/ie_auto.sh
fi
```
If `ie_auto.sh` is found on the writeable configuration partition, it is executed as root.

---

## 3. Resolving the Watchdog and Wi-Fi Blocks

We encountered three main hurdles when attempting to run custom scripts via this hook:

### The Foreground Blocking Loop
The stock `bootstrap.sh` does not fork `ie_auto.sh` into the background. If a custom hook runs an infinite loop (e.g. to feed the watchdog), the bootloader hangs and the Wi-Fi interface never gets initialized. We resolved this by wrapping all blocking operations (waiting for interface, running DHCP, watchdog feed loops) in a background subshell `( ... ) &`.

### The -W wpa_supplicant Block
The stock startup script launches the Wi-Fi daemon with the `-W` parameter:
```bash
nice -n 20 wpa_supplicant -iwlan0 -c/mnt/dropcam/wpa_supplicant.conf -Dnl80211 -W -B
```
The `-W` flag forces `wpa_supplicant` to remain dormant and never associate with an AP until an active client connects to its control socket. Since we blocked the Nest client from running, the card remained disconnected.
*   **The Argument-Stripping Solution:** We created a wrapper script that copies `/sbin/wpa_supplicant` to `/tmp/wpa_supplicant_real`, intercepting all system execution calls to `wpa_supplicant` and dropping the `-W` argument from the arguments list dynamically before executing the real binary. We then bind-mounted this wrapper directly over the system binary `/sbin/wpa_supplicant`.

### Proprietary Client Overrides
As soon as the interface gets Wi-Fi, the stock system starts the proprietary `/usr/bin/connect` cloud client. If it cannot reach the Nest servers, it periodically resets the Wi-Fi link and reboots the camera.
*   **The Bind-Mount Override:** Since the root filesystem is read-only, we wrote a dummy script that sleeps forever and bind-mounted it over `/usr/bin/connect` at startup. This successfully prevents the proprietary Nest software from executing without generating CPU load.

# FAQ (Frequently Asked Questions)

Here are answers to the most common questions regarding firmware modifications and offline operations.

---

## 1. Do I need to compile a custom Linux kernel?
No. The temporary kernel we boot into RAM (`zImage` and `initrd.lzma`) is from the `gopro-usb-tools` project, which is fully compatible with the Ambarella A5s hardware. Once we write the JFFS2 payload, we reboot and use the camera's original, stock Ambarella Linux kernel.

## 2. Does this exploit require any soldering?
No. The Ambarella A5s boot ROM natively supports entering a USB Command mode (DFU mode) when a physical button is held down at power-on. This allows the host PC to upload binaries directly to the RAM, bypassing any flash memory write blocks.

## 3. Can I use the camera locally for video streaming (RTSP)?
Yes. Now that you have root shell access, you can run a comaptible rtsp streamer. (Il be working on some software to have the full capabilities of the dropcam in home assistant later on.) You can configure `ie_auto.sh` to start a local RTSP server to stream video directly into home automation hubs (e.g. Home Assistant, Frigate) completely offline.

## 4. What happens if I make a mistake in `ie_auto.sh`?
If `ie_auto.sh` is corrupted or crashes, the camera simply fails to mount or execute the hook and falls back to standard USB provisioning mode (appearing as a virtual USB drive). You can easily recover by running `./root_camera.sh` and selecting option 1 to boot into RAM and re-flash it.

## 5. How do I permanently change the root password?
Log into the camera via Telnet (`telnet 192.168.75.2` or your Wi-Fi IP) and run the `passwd` command. The updated password hashes will be saved to `/mnt/dropcam/shadow` and will persist across reboots.

## 6. How do I change the Wi-Fi network credentials?
Run the `rooted_toolkit.sh` script on your host PC, select option 2 (Edit Wi-Fi credentials), type the new SSID and Password, and the script will automatically overwrite `/mnt/dropcam/wpa_supplicant.conf` on the camera over the network.

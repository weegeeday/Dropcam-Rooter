# How-To Guide: Rooting and Configuring the Dropcam

This guide provides step-by-step instructions on preparing your hardware, setting up the host software, and executing the jailbreak scripts.

---

## Step 1: Locating the Physical Bootloader Button

To flash code over USB, you must force the Ambarella SoC into DFU (Device Firmware Upgrade) command mode. This is done by holding down the physical bootloader button while powering on the camera.

*   **Location:** On the Dropcam 2013, this button is located on the back panel of the internal camera assembly.
*   **Access Methods:**
    *   **Pinhole:** There is a small pinhole on the back case of the camera. You can insert a paperclip or SIM eject tool to hold down the tactile button.
    *   **Disassembly:** If the pinhole is difficult to align, you can unscrew the outer plastic shell to expose the internal PCB, exposing the tactile switch directly.

---

## Step 2: DFU Boot Protocol (Putting Camera in USB Command Mode)

To put the camera into DFU mode:
1.  Unplug the USB cable from the camera.
2.  Press and **hold** the physical bootloader button.
3.  Connect the Micro-USB cable from your host Linux PC to the camera.
4.  Wait 2 seconds, then release the bootloader button.

The front LED will remain off (appearing dead), but the camera will enumerate on your host system as a USB device under VID:PID `4255:0001` (Ambarella Bootloader).

---

## Step 3: Preparing the Host Environment

1.  Open a terminal on your host Linux PC.
2.  Clone the repository and run the setup script:
    ```bash
    chmod +x setup.sh
    ./setup.sh
    ```
3.  The setup script will prompt you for the stock GoPro Hero2 firmware file (`HD2-firmware.bin`) which is required to extract the necessary BLD and HAL bootstrap files. Place this file in the parent directory when prompted.

---

## Step 4: Running the Jailbreak

1.  Ensure the camera is plugged in and in DFU mode (as configured in Step 2).
2.  Run the rooting utility:
    ```bash
    chmod +x root_camera.sh
    ./root_camera.sh
    ```
3.  Enter your Wi-Fi SSID and Password when prompted.
4.  Choose **Option 1** to boot the RAM kernel. The script will automatically:
    *   Initialize the host USB interface.
    *   Load the temporary kernel over USB.
    *   Establish a network link to the RAM kernel at `10.9.9.1`.
    *   Trigger the NAND driver and pull the stock configuration (`adc.bin`).
    *   Apply the root passwordless patch, inject the custom `ie_auto.sh` hook, and write the Wi-Fi credentials.
    *   Recompile the modified partition image and flash it back to the physical flash memory.

Once the flashing completion message is displayed, unplug the USB cable.

---

## Step 5: Post-Install Setup and Security

After flashing, plug the camera into a standard USB wall charger (or leave it connected to the PC to boot normally). The camera will execute `ie_auto.sh` at startup, set up the static USB network interface at `192.168.75.2`, connect to your Wi-Fi, and launch SSH and Telnet.

We recomend using the rooted toolkit mentioned in step 6 to connect when using usb. If using telnet over wifi, you can simply use that.

### Securing the Shell
By default, the root password is empty to ensure you can gain initial access. For security, you must log in immediately and set a password:

1.  Connect to the camera:
    ```bash
    telnet 192.168.x.x
    ```
2.  Run the standard password configuration utility:
    ```bash
    passwd
    ```
3.  Follow the prompts to configure a secure password. The change will persist permanently across reboots on the writeable config partition.

---

## Step 6: Post-Jailbreak Management Toolkit

Once the camera is rooted, you can manage it using the toolkit script:
```bash
chmod +x rooted_toolkit.sh
./rooted_toolkit.sh
```
This utility provides menu options to quickly open shells, reconfigure Wi-Fi networks, or push custom boot script updates over the air or USB cable.

# 📱 Headless-Android-Rescue: Universal Blind Unbrick & Headless Provisioning
> **A field-tested methodology to recover, flash, and provision completely headless (broken display) Android devices using low-level fault injection, hardware cues, synthetic kernel touch events, and persistent Magisk automation.**

![Verified On](https://img.shields.io/badge/Verified%20Device-Redmi%209A%20%2F%209i%20(dandelion%2Fblossom)-blue)
![Platform](https://img.shields.io/badge/SoC-MediaTek%20MT6765%20(Helio%20G25)-orange)
![Target OS](https://img.shields.io/badge/Target%20OS-LineageOS%2020%20(Android%2013)-brightgreen)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📖 Overview & Motivation

A broken digitizer/display usually renders an Android phone an inaccessible paperweight:
* Touch is inoperable, preventing acceptance of "Allow USB Debugging" RSA prompts.
* Display is dead, making blind TWRP/recovery navigation almost impossible.
* Fastboot recovery booting (`fastboot boot recovery.img`) is rejected on modern MediaTek bootloaders.
* Budget platforms (e.g., MT6765 with 2GB Micron RAM) suffer from known EMI freeze bugs during BROM handshakes.

This project documents a **100% reproducible recovery framework** developed on a physically blind **Redmi 9A / 9i (`dandelion` / `blossom`)**, successfully transitioning it from Stock MIUI 12.5 (Android 11) to a fully functional, headless **LineageOS 20 (Android 13 userdebug)** controlled seamlessly via `scrcpy` over USB/Wi-Fi.

> 💡 **Universality:** While MTK hardware loaders are chipset-specific, the core principles—**RescueParty fault induction, backlight PWM visual cues, synthetic kernel event injection (`sendevent`), and Magisk late-service ADB provisioning**—apply universally across ~90% of Android devices.

---

## 🧠 Key Discoveries & Technical Ground Truths

### 1. The 2GB Micron RAM EMI Freeze Bug
On Redmi 9A/9i units equipped with 2GB Micron LPDDR4X RAM, standard MTKClient freezes at `Sending EMI data`.
* **Fix:** Use a patched custom DA loader (`n.bin`) alongside the stock preloader:
```bash
python3 mtk.py <command> --loader n.bin --preloader preloader_k62v1_64_bsp.bin
```

### 2. Stock VBMeta & The Backlight Transition Cue
* Altering or zeroing `vbmeta` on Android 11 causes Little Kernel (LK) crash loops. We retain the **genuine stock `vbmeta.img`**.
* **Fault Injection:** Erasing `userdata` (`mtk e userdata`) creates an unmountable condition, intentionally triggering Android's native **RescueParty** loop.
* **The Hardware Visual Cue (Crucial Discovery):**
  1. During a normal boot attempt, the screen backlight turns on with **High Brightness**, stays for a few seconds, and resets.
  2. The moment the high-brightness backlight illuminates, **immediately press and hold the Power Button**.
  3. **The Signature Indicator:** The backlight will abruptly drop from **High Brightness to Low Brightness**. This transition is the definitive physical cue that Little Kernel (LK) intercepted the reboot and handed execution over to the TWRP recovery kernel!

---

### 3. Synthetic Multi-Touch Emulation (`/dev/input/event*`)
TWRP requires an interactive "Swipe to confirm Flash" slider before installing any ZIP. Without a working screen, this is bypassed by injecting raw multi-touch Type-B packets into the kernel input subsystem.

* **Target Node:** `/dev/input/event3` (`NVTCapacitiveTouchScreen`)
* **Resolution Bounds:** `X: 0..719`, `Y: 0..1599`
* **Slider Coordinates:** Centered horizontally at bottom ($Y \approx 1420$, $X: 150 \rightarrow 660$)

Executing `scripts/swipe_install.sh` feeds synthetic touch down, drag, and touch up events, prompting TWRP to immediately flash the ROM without human touch.

---

### 4. Headless Magisk ADB Provisioning
Fresh custom ROM installations default to charging or MTP-only mode (`2717:ff40`). Because the screen cannot be tapped to enable Developer Options:
1. Flash `Magisk.zip` via synthetic swipe.
2. Deploy a late-start daemon into `/data/adb/service.d/enable_adb.sh` (executed as root after `/data` is decrypted and `sys.boot_completed=1`).
3. The daemon programmatically sets:
   * `settings put global adb_enabled 1`
   * `setprop persist.sys.usb.config mtp,adb`
   * `resetprop ro.adb.secure 0` (bypasses RSA authorization dialog)
4. Pre-provision the PC's public key (`~/.android/adbkey.pub`) directly into `/data/misc/adb/adb_keys` (`chmod 640`, owner `1000:2000`).

On subsequent system boot, ADB connects automatically with full root authorization, and `scrcpy` initializes effortlessly.

---

## 🛠️ Step-by-Step Reproduction Guide

### Prerequisites
* Linux host (e.g. Linux Mint / Ubuntu)
* [mtkclient](https://github.com/bkerler/mtkclient) with `n.bin` loader
* Stock firmware images (`preloader_k62v1_64_bsp.bin`, `vbmeta.img`)
* TWRP 3.7.1 for `dandelion`/`blossom`
* LineageOS 20 ZIP & matching `boot.img`
* Magisk ZIP

### Execution Flow
```bash
# 1. Flash TWRP & Stock VBMeta via MTKClient BROM
python3 mtk.py w recovery twrp-3.7.1.img --loader n.bin --preloader preloader.bin
python3 mtk.py w vbmeta vbmeta.img --loader n.bin --preloader preloader.bin
python3 mtk.py e userdata,metadata --loader n.bin --preloader preloader.bin

# 2. Boot to TWRP using the Backlight Timing Trick
# (Power on -> High brightness -> Hold Power -> Watch for Low brightness drop -> Plug USB)

# 3. Format Data in TWRP & Flash Kernel
adb shell twrp format data
adb push lineage/boot.img /tmp/boot.img
adb shell "dd if=/tmp/boot.img of=/dev/block/by-name/boot"

# 4. Push ROM & Trigger Synthetic Swipe Installation
adb push lineage-20.0-blossom.zip /data/lineage.zip
./scripts/swipe_install.sh /data/lineage.zip

# 5. Flash Magisk & Provision Headless ADB Daemon
./scripts/swipe_install.sh /tmp/Magisk.zip
./scripts/setup_magisk_adb.sh

# 6. Reboot to System & Launch Scrcpy
adb reboot
# Wait 2-3 minutes for first boot...
scrcpy
```

---

## 📦 Binary Files & Third-Party Dependencies

To comply with licensing and prevent potential DMCA takedowns regarding proprietary vendor binaries:
* **`n.bin` & Stock Preloader:** Extracted from community-patched MTK DA packages. Download links and SHA256 checksums are hosted under the [GitHub Releases](../../releases) section.
* **TWRP Recovery:** TeamWin Recovery Project (GPL v3). Source trees available at [TeamWin](https://github.com/TeamWin).
* **Magisk:** Distributed under GNU GPL v3 by [topjohnwu](https://github.com/topjohnwu/Magisk).

---

## 🙏 Credits & Acknowledgments
* **XDA Developers Community** for hardware research and custom MTK Download Agent loaders.
* **B. Kerler** for the incredible [mtkclient](https://github.com/bkerler/mtkclient) reverse-engineering tool.
* **John Wu (topjohnwu)** for [Magisk](https://github.com/topjohnwu/Magisk).
* **LineageOS maintainers** for supporting the `blossom` device tree.

---

## 🤝 Community Disclaimer & Contributions

> *"If there are any factual inaccuracies, technical oversights, or unintended mistakes in this guide, please forgive them. We are all continuous learners. Contributions, feedback, and pull requests are warmly welcomed to help improve this methodology for everyone!"*

Developed with determination by an 18-year-old student enthusiast. Open-source belongs to the community.
```

---

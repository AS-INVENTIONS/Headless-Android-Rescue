#!/bin/bash
echo "1. Magisk.zip ഫോണിലേക്ക് കോപ്പി ചെയ്യുന്നു..."
adb push ~/phone/Magisk.zip /tmp/Magisk.zip

echo "2. TWRP-യിൽ Magisk ഇൻസ്റ്റാൾ പേജ് തുറക്കുന്നു..."
adb shell twrp install /tmp/Magisk.zip
sleep 1

echo "3. വെർച്വൽ സ്വൈപ്പ് വഴി Magisk ഫ്ലാഷ് ചെയ്യുന്നു..."
adb shell "
for Y in 1420 1460; do
    sendevent /dev/input/event3 3 47 0
    sendevent /dev/input/event3 3 57 1
    sendevent /dev/input/event3 1 330 1
    sendevent /dev/input/event3 3 48 100
    sendevent /dev/input/event3 3 58 500
    sendevent /dev/input/event3 3 54 \$Y
    for X in 150 200 250 300 350 400 450 500 550 600 660; do
        sendevent /dev/input/event3 3 53 \$X
        sendevent /dev/input/event3 0 0 0
        usleep 10000
    done
    sendevent /dev/input/event3 3 57 -1
    sendevent /dev/input/event3 1 330 0
    sendevent /dev/input/event3 0 0 0
    sleep 0.5
done
"

echo "Magisk ഫ്ലാഷ് ആകാൻ 15 സെക്കൻഡ് കാത്തിരിക്കുന്നു..."
sleep 15

echo "4. /data പാർട്ടിഷൻ മൗണ്ട് ചെയ്യുന്നു..."
adb shell "twrp mount data || mount /data"

echo "5. Magisk-നുള്ളിൽ എപ്പോഴും ADB ഓൺ ആക്കാനുള്ള സർവീസ് സ്ക്രിപ്റ്റ് ഉണ്ടാക്കുന്നു..."
adb shell "mkdir -p /data/adb/service.d"

adb shell 'cat << "INNER_EOF" > /data/adb/service.d/enable_adb.sh
#!/system/bin/sh
# സിസ്റ്റം പൂർണ്ണമായി ഓൺ ആകുന്നത് വരെ കാത്തിരിക്കുന്നു
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
done

# USB Debugging ഓൺ ആക്കുന്നു
settings put global adb_enabled 1
settings put global development_settings_enabled 1

# സ്ക്രീനിൽ അനുമതി ചോദിക്കുന്നത് ഒഴിവാക്കുന്നു
resetprop ro.adb.secure 0
resetprop ro.secure 0
resetprop ro.debuggable 1

# USB മോഡ് MTP + ADB ആക്കി മാറ്റുന്നു
setprop persist.sys.usb.config mtp,adb
setprop sys.usb.config mtp,adb
INNER_EOF
'

adb shell "chmod 755 /data/adb/service.d/enable_adb.sh"

echo "6. നിങ്ങളുടെ PC-യുടെ ADB Key ഫോണിലേക്ക് നേരിട്ട് കയറ്റുന്നു..."
adb shell "mkdir -p /data/misc/adb"
adb push ~/.android/adbkey.pub /data/misc/adb/adb_keys
adb shell "chown -R 1000:2000 /data/misc/adb; chmod 640 /data/misc/adb/adb_keys"

echo "7. റിക്കവറി ഫ്ലാഗ് മായ്ച്ച് സിസ്റ്റത്തിലേക്ക് പോകാൻ ഓർഡർ നൽകുന്നു..."
adb shell "dd if=/dev/zero of=/dev/block/by-name/para bs=1024 count=2 2>/dev/null; dd if=/dev/zero of=/dev/block/by-name/misc bs=1024 count=2 2>/dev/null"

echo "8. പുത്തൻ LineageOS 20-ലേക്ക് ഫോൺ റീബൂട്ട് ചെയ്യുന്നു..."
adb reboot

echo "എല്ലാം വിജയകരമായി കഴിഞ്ഞു! ഫോൺ ഓൺ ആകാൻ 2-3 മിനിറ്റ് കാത്തിരിക്കുക..."

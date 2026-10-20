#!/bin/bash
echo "1. TWRP ഇൻസ്റ്റാൾ പേജ് തുറക്കുന്നു..."
adb shell twrp install /data/lineage.zip
sleep 1

echo "2. വെർച്വൽ ആയി സ്ക്രീനിൽ സ്വൈപ്പ് ചെയ്യുന്നു..."
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

echo "3. TWRP ലോഗ് പരിശോധിക്കുന്നു..."
sleep 2
adb shell "tail -n 25 /tmp/recovery.log"

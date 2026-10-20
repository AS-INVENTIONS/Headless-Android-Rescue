#!/usr/bin/env python3
# Generates a raw Bootloader Control Block (BCB) binary
with open("misc.bin", "wb") as f:
    b = bytearray(2048)
    cmd = b"boot-recovery"
    b[:len(cmd)] = cmd
    rec = b"recovery\n"
    b[64:64+len(rec)] = rec
with open("misc.bin", "wb") as f:
    f.write(b)
print("[+] Successfully generated misc.bin")

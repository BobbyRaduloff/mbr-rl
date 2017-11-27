@echo off
nasm -f bin mbr-rl.asm -o mbr-rl.bin
qemu-system-i386 -drive format=raw,file=mbr-rl.bin
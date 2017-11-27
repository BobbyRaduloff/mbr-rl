@echo off
nasm -f bin mbr-rl.asm -o mbr-rl.img
qemu-system-i386 -drive format=raw,file=mbr-rl.img
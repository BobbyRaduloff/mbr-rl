CODE = mbr-rl.asm
OUT = mbr-rl.img
ASM = nasm
ASMOPTS = -f bin
EMU = qemu-system-i386
EMUOPTS = -drive format=raw,file=$(OUT)

all:
	$(ASM) $(ASMOPTS) $(CODE) -o $(OUT)

run: all
	$(EMU) $(EMUOPTS)

delete:
	rm $(OUT)
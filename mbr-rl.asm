; BIOS Preperation
org 0x7c00 ; BIOS loads here
bits 16 ; 16 bit real mode

; Clear the screen by changing screen mode to 80x25
%macro clear_screen 0
	push ax
	mov ax, 0x0003 ; ah = 0x00 -> set video mode; al = 0x03 -> 80x25 16 colors
	int 0x10
	pop ax
%endmacro

; Write a character (%1) to a specific x (%2), y (%3) position.
%macro set_char 3
	pusha ; Pushing and popping all instead of spceifying which three saves code space
	mov ah, 0x02 ; Set cursor position
	mov dh, %2 ; X coord
	mov dl, %3 ; Y coord
	int 0x10
	mov ah, 0x0a ; Write to cursor
	mov al, %1 ; Character to write
	mov cx, 1 ; Write the character once
	int 0x10
	; Maybe writing directly to 0xb800 will be faster
	; In a setup routine, set es to 0xb800
	; and then write to es:ax
	; OR EVEN
	; =>
	; %macro set_char 3
	; 	mov [0x0:0xb800 + %2 * 80 + %3], %1
	; %endmacro
	popa
%endmacro

start:
	clear_screen
	set_char '@', 1, 1
halt:
	hlt

; Write MBR Signature
times 510-($-$$) db 0 ; Fill rest with 0
dw 0xaa55 ; MBR Signature

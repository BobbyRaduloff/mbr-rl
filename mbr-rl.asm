; BIOS Preperation
org 0x7c00 ; BIOS loads here
bits 16 ; 16 bit real mode

; Write char al (%1) with bl (%4) as foreground color at (dl (%2), dh (%3))
; Colors (http://www.shikadi.net/moddingwiki/B800_Text):
; 	0x1 - blue
;	0x2 - green
;	0x3 - cyan
; 	0x4 - red
;	0x5 - magenta
; 	0x6 - brown
;	0xe - yellow
;	0xf - white
%macro set_char 4
	pusha
	mov al, %1
	mov bl, %4
	mov dl, %2
	mov dh, %3
	call _set_char
	popa
%endmacro

; Reads character (dl, dh) into AL
%macro read_char 2
	mov dl, %1
	mov dh, %2
	call _read_char
%endmacro

start:
initiliaze_variables:
; Player initialy positioned in the middle
mov byte [px], 38
mov byte [py], 12
initialize_video:
	; Set up mode 0x03
	mov ax, 0x0003 ; ah = 0x0 -> set video mode
	int 0x10 ; al = 0x3 -> 80x25 16 colors
	; Setting up FS to point to the display buffer so that we can write to it.
	mov ax, 0xb800 ; Set AX to point to buffer
	mov fs, ax ; Set FS to point to buffer

game_loop:
	; The actual game loop
draw_background:
	; Fills the entire screen with '#' in a single interrupt, the '#' will act as map border
	; It will be overwriten by the repeated _draw_line; done to save code space
	mov ax, 0x0923 ; ah = 0x0a -> write char; al = 0x23 = '#'
	mov bl, 0xf; White background
	mov cx, 2000 ; 2000 = 80 * 25 = entire screen
	int 0x10
	; Draw the beloved dotted RL background
	mov dh, 1 ; Set to 0-th row so that when incremented, it leaves a gap up
	mov dl, 3 ; Set to 2-nd column so that it leaves a gap to the left
_draw_line:
	inc dh ; increment to next row
	mov ah, 0x02 ; Move cursor to (dl, dh)
	int 0x10
	mov ax, 0x0a2e ; ah = 0x0a -> write char; al = 0x2e = '.'
	mov cx, 74 ; Write it 74 times so it leaves a gap to the right
	int 0x10
	cmp dh, 22 ; If we are on the second to last (small gap) line, stop drawing more lines
	jl _draw_line

	set_char 1, [px], [py], 0x2 ; draw the player
check_keys:
	xor ax, ax ; zero ax for keyboard return
	int 0x16
	cmp ah, 0x11 ; 0x11 = scancode(w)
	je _w
	cmp ah, 0x1f ; 0x1f = scancode(s)
	je _s
	cmp ah, 0x1e ; 0x1e = scancode(a)
	je _a
	cmp ah, 0x20 ; 0x20 = scancode(d)
	je _d
	jmp ai

_w:
	cmp byte [py], 2
	jle ai
	dec byte [py]
	jmp ai
_s:
	cmp byte [py], 22	
	jge ai
	inc byte [py]
	jmp ai
_a:
	cmp byte [px], 3
	jle ai
	dec byte [px]
	jmp ai
_d:
	cmp byte [px], 76
	jge ai
	inc byte [px]
	jmp ai

ai:
	jmp game_loop

halt:
	hlt

_set_char:
	mov ah, 0x02 ; move cursor to (dl, dh)
	int 0x10
	mov ah, 0x09 ; write char and attribute
	mov cx, 0x1 ; only once
	int 0x10
	ret

_read_char:
	mov ah, 0x02 ; move cursor to (dl, dh)
	int 0x10
	mov ah, 0x08 ; Read character into AL
	int 0x10
	ret

; Game State Data
px: equ 8000 ; half of the width
py: equ 8001 ; half of the height

; Dummy partition entry (https://github.com/daniel-e/tetros/blob/master/tetros.asm)
times 446-($-$$) db 0
	db 0x80                   ; bootable
    db 0x00, 0x01, 0x00       ; start CHS address
    db 0x17                   ; partition type
    db 0x00, 0x02, 0x00       ; end CHS address
    db 0x00, 0x00, 0x00, 0x00 ; LBA
    db 0x02, 0x00, 0x00, 0x00 ; number of sectors

; Write MBR Signature
times 510-($-$$) db 0 ; Fill rest with 0
dw 0xaa55 ; MBR Signature

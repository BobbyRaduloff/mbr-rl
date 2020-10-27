;; BIOS Preperation
org 0x7c00 ; BIOS loads here
bits 16 ; 16 bit real mode


;; Set VideoMode to 80x25
    mov ax, 0x002
    int 0x10

;; Set up drawing prerequisites
    cld ; stosw now incerements stream registers
    mov ax, 0xb800
    mov es, ax
    mov di, 0

;; Initialization
initialize_variables:
    mov [player_hp], byte 2
    mov [player_x], byte 39
    mov [player_y], byte 11
    call random_hp_pickup

;; GAME LOOP
GAME_LOOP:
pusha

;; Drawing code
; Draw the top and bottom lines
draw_horizontal_lines:
    mov ax, 0x0fdb
    mov cx, 80
    .draw_top_line_loop:
        stosw
    loop .draw_top_line_loop
    mov di, 3680
    mov cx, 80
    .draw_bottom_line_loop:
        stosw
    loop .draw_bottom_line_loop

; Draw the left and right lines
draw_vertical_lines:
    mov ax, 0x0fdb
    mov cx, 23
    mov di, 160
    .draw_left_line_loop:
        stosw
        add di, 158
    loop .draw_left_line_loop
    mov cx, 23
    mov di, 158
    .draw_right_line_loop:
        stosw
        add di, 158
    loop .draw_right_line_loop

; Draw the dots
draw_dots:
    mov bx, 22
    mov ax, 0x0ffa
    mov di, 162
    .draw_next_line:
        mov cx, 78
        .draw_dotted_line:
        stosw
        loop .draw_dotted_line
        add di, 4
    cmp di, 3680
    jle .draw_next_line

; Draw the health UI
draw_health:
    mov cx, 3
    mov di, 3840
    xor ax, ax
    mov ds, ax
    lea si, health_text
    .draw_health_loop:
        lodsw
        stosw
    loop .draw_health_loop
    mov al, [player_hp]
    add al, 0x30
    stosb
    mov al, 0x04
    stosb

; Draw the player
draw_player:
    mov ax, [player_x]
    mov bx, [player_y]
    mov cx, 0x0201
    call set_char

draw_hp_pickup:
    mov ax, [hp_x]
    mov bx, [hp_y]
    mov cx, 0x0403
    call set_char

;; END OF GAME LOOP
    hlt
    popa
    jmp GAME_LOOP

;; Functions and macros
calculate_location_offset: ; (x = ax, y = bx -> di = memory location)
    mov di, ax
    add di, ax
    mov ax, bx
    mov bx, 0x00a0
    mul bl
    add di, ax
    ret

set_char: ; (char = cx)
    call calculate_location_offset
    mov ax, cx
    stosw
    ret

random_hp_pickup:
    pusha
    rdtsc
    xor dx, dx
    mov cx, 22
    div cx
    mov ax, dx
    add ax, 2
    mov [hp_y], al
    rdtsc
    xor dx, dx
    mov cx, 77
    div cx
    mov ax, dx
    add ax, 2
    mov [hp_x], al
    popa
    ret

;; Variables
player_x: resb 1
player_y: resb 1
hp_x: resb 1
hp_y: resb 1
player_hp: resb 1

;; Constants
health_text db 'H', 0x04, 'P', 0x04, ':', 0x04

;; Dummy partition table (https://github.com/daniel-e/tetros/blob/master/tetros.asm)
times 446-($-$$) db 0
	db 0x80                   ; bootable
    db 0x00, 0x01, 0x00       ; start CHS address
    db 0x17                   ; partition type
    db 0x00, 0x02, 0x00       ; end CHS address
    db 0x00, 0x00, 0x00, 0x00 ; LBA
    db 0x02, 0x00, 0x00, 0x00 ; number of sectors

;; Write MBR Signature
times 510-($-$$) db 0 ; Fill rest with 0
dw 0xaa55 ; MBR Signature

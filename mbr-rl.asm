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

;; MACROS
%macro set_char 3
    pusha
    mov di, 0
    mov cl, byte [%2]
    .set_y:
    add di, 160
    loop .set_y
    xor ax, ax
    mov al, byte [%1]
    add di, ax
    add di, ax
    mov ax, %3
    stosw
    popa
%endmacro
%macro random_hp_pickup 0
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
%endmacro

;; Initialization
initialize_variables:
    mov [player_hp], byte 1
    mov [player_x], byte 39
    mov [player_y], byte 11
    random_hp_pickup

;; GAME LOOP
GAME_LOOP:
;; Draw the game world
; Draw the top and bottom lines
pusha
draw_horizontal_lines:
    mov bx, 1
    mov cx, 80
    mov ax, 0x0fdb
    .draw_horizontal_lines_loop:
    stosw
    loop .draw_horizontal_lines_loop
    or bx, bx
    jz .draw_horizontal_lines_exit
    dec bx
    mov di, 3680
    mov cx, 80
    jmp .draw_horizontal_lines_loop
    .draw_horizontal_lines_exit:
; Draw the left and right lines
draw_vertical_lines:
    mov bx, 1
    mov cx, 23
    mov ax, 0x0fdb
    mov di, 160
    .draw_vertical_lines_loop:
    stosw
    add di, 158
    loop .draw_vertical_lines_loop
    or bx, bx
    jz .draw_vertical_lines_exit
    dec bx
    mov di, 158
    mov cx, 23
    jmp .draw_vertical_lines_loop
    .draw_vertical_lines_exit:
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
    set_char player_x, player_y, 0x0201
draw_hp_pickup:
    set_char hp_x, hp_y, 0x0403

;; Movement code
read_input:
    xor dx, dx
    xor cx, cx
    mov ah, 0
    int 16h
    mov bx, [player_y]
    mov dx, [player_x]
    cmp al, 119 ; w
    je .w
    cmp al, 97 ; a
    je .a
    cmp al, 115 ; s
    je .s
    cmp al, 100 ; d
    je .d
    jmp read_input
    .w:
    mov ax, 0xb800
    add ax, [player_x]
    add ax, [player_x]
    mov cx, 160
    .w_loop:
    add ax, [player_y]
    dec ax
    loop .w_loop
    dec bx
    jmp .handle_input
    .a:
    mov ax, 0xb800
    add ax, [player_x]
    add ax, [player_x]
    sub ax, 2
    mov cx, 160
    .a_loop:
    add ax, [player_y]
    loop .a_loop
    dec dx
    jmp .handle_input
    .s:
    mov ax, 0xb800
    add ax, [player_x]
    add ax, [player_x]
    mov cx, 160
    .s_loop:
    add ax, [player_y]
    inc ax
    loop .s_loop
    inc bx
    jmp .handle_input
    .d:
    mov ax, 0xb800
    add ax, [player_x]
    add ax, [player_x]
    add ax, 2
    mov cx, 160
    .d_loop:
    add ax, [player_y]
    loop .d_loop
    inc dx
    jmp .handle_input
    .handle_input:
    cmp ax, 0x0fdb
    je read_input
    cmp ax, 0x0403
    jne .skip_heart
    inc byte [player_hp]
    random_hp_pickup
    .skip_heart:
    mov [player_x], dx
    mov [player_y], bx

    popa
    jmp GAME_LOOP
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

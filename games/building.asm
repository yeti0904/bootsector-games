; building game
; made by yeti0904 in 19th December 2022
; my first boot sector game

[bits 16]
[org 0x7C00]

; memory stuff
%define PPOSX 0xA0001
%define PPOSY 0xA0008

%define BLOCKMODE        0xA0010
%define BLOCKMODEPLACE   1
%define BLOCKMODEDESTROY 0

jmp boot

; util functions
clear:
	pusha

	mov ax, 0x0700  ; function 07, AL=0 means scroll whole window
	mov bh, 0x07    ; character attribute = white on black
	mov cx, 0x0000  ; row = 0, col = 0
	mov dx, 0x184f  ; row = 24 (0x18), col = 79 (0x4f)
	int 0x10        ; call BIOS video interrupt

	mov ah, 0x02
	mov bh, 0
	mov dh, 0
	mov dl, 0
	int 0x10

	popa
	ret


;puts:
;	pusha
;	mov ah, 0x0E ; teletype output
;	.loop:
;		lodsb
;		cmp al, 0 ; null terminator
;		je .done
;		int 0x10
;		jmp .loop
;	.done:
;		popa
;		ret


getchar:
	mov  ah, 0x00
	int  0x16
	ret

moveCursor:
	mov ah, 2 ; set cursor position
	mov bh, 0 ; page number
	int 0x10
	ret

; game functions
deletePlayer:
	mov dh, byte [PPOSY]
	mov dl, byte [PPOSX]
	call moveCursor

	mov al, ' '
	mov ah, 0x0E
	int 0x10
	ret

drawPlayer:
	mov dh, byte [PPOSY]
	mov dl, byte [PPOSX]
	call moveCursor

	mov al, 2 ; filled smiley face
	mov ah, 0x0E
	int 0x10
	ret

swapBlockMode:
	cmp [BLOCKMODE], byte BLOCKMODEPLACE
	je .destroy
	jne .place
	.place:
		mov dh, 0
		mov dl, 0
		call moveCursor

		mov al, 'P'
		mov ah, 0x0E
		int 0x10

		mov byte [BLOCKMODE], byte BLOCKMODEPLACE
		ret
	.destroy:
		mov dh, 0
		mov dl, 0
		call moveCursor

		mov al, 'D'
		mov ah, 0x0E
		int 0x10

		mov byte [BLOCKMODE], byte BLOCKMODEDESTROY
		ret

drawBlock:
	cmp byte [BLOCKMODE], BLOCKMODEPLACE
	je .place
	jne .delete
	.place:
		mov al, 0xDB
		jmp .do
	.delete:
		mov al, ' '
		jmp .do

	.do:
		mov dh, byte [PPOSY]
		mov dl, byte [PPOSX]
		call moveCursor

		mov ah, 0x0E
		int 0x10
		ret

playerCollides:
	mov dh, byte [PPOSY]
	mov dl, byte [PPOSX]
	call moveCursor

	mov ah, 0x08 ; read character
	mov bh, 0    ; page number
	int 0x10
	cmp al, ' '
	ret

boot:
	; disable cursor
	mov ah, 1  ; change cursor shape
	mov ch, 32 ; disable cursor
	int 0x10

	call clear

	mov byte [PPOSX], 5
	mov byte [PPOSY], 5
	call drawPlayer
	
	mov byte [BLOCKMODE], byte BLOCKMODEDESTROY
	call swapBlockMode

	.gameLoop:
		call getchar

		; movement keys
		cmp al, 'w'
		je .moveUp
		
		cmp al, 's'
		je .moveDown
		
		cmp al, 'a'
		je .moveLeft
		
		cmp al, 'd'
		je .moveRight

		; building keys
		cmp al, 'i'
		je .buildUp

		cmp al, 'k'
		je .buildDown

		cmp al, 'j'
		je .buildLeft

		cmp al, 'l'
		je .buildRight

		; etc
		cmp al, ' '
		je .swapBlockMode
		
		jmp .gameLoop

	.swapBlockMode:
		call swapBlockMode
		jmp .gameLoop
		
	.moveUp:
		cmp byte [PPOSY], 0
		je .gameLoop
		
		call deletePlayer
		dec byte [PPOSY]
		call playerCollides
		jne .collideUp
		call drawPlayer
		jmp .gameLoop
	.collideUp:
		inc byte [PPOSY]
		call drawPlayer
		jmp .gameLoop
		
	.moveDown:
		cmp byte [PPOSY], 24
		je .gameLoop
	
		call deletePlayer
		inc byte [PPOSY]
		call playerCollides
		jne .collideDown
		call drawPlayer
		jmp .gameLoop
	.collideDown:
		dec byte [PPOSY]
		call drawPlayer
		jmp .gameLoop
		
	.moveLeft:
		cmp byte [PPOSX], 0
		je .gameLoop
	
		call deletePlayer
		dec byte [PPOSX]
		call playerCollides
		jne .collideLeft
		call drawPlayer
		jmp .gameLoop
	.collideLeft:
		inc byte [PPOSX]
		call drawPlayer
		jmp .gameLoop
		
	.moveRight:
		cmp byte [PPOSX], 79
		je .gameLoop
	
		call deletePlayer
		inc byte [PPOSX]
		call playerCollides
		jne .collideRight
		call drawPlayer
		jmp .gameLoop
	.collideRight:
		dec byte [PPOSX]
		call drawPlayer
		jmp .gameLoop

	.buildUp:
		dec byte [PPOSY]
		call drawBlock
		inc byte [PPOSY]
		jmp .gameLoop

	.buildDown:
		inc byte [PPOSY]
		call drawBlock
		dec byte [PPOSY]
		jmp .gameLoop

	.buildLeft:
		dec byte [PPOSX]
		call drawBlock
		inc byte [PPOSX]
		jmp .gameLoop

	.buildRight:
		inc byte [PPOSX]
		call drawBlock
		dec byte [PPOSX]
		jmp .gameLoop

	jmp $

times 510-($-$$) db 0
dw 0xAA55

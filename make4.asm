;
; Make4.asm
;

; Constant - the file size
FILE_SIZE EQU (eof-$$)

; All COM programs start at 0x100
org 0x100

;
; BA 15 01
mov dx, filename		; Saves the filename to create in DX

;
; 91
; B4 5B
; CD 21
xchg ax, cx				; File attributes (sets to 0 as 0xFF is invalid - http://justsolve.archiveteam.org/wiki/DOS/Windows_file_attributes)
mov ah, 0x5B
int 0x21				; DOS interrupt 21,5B - Create File

;
; 93
; B1 16
; 87 D6
; B4 40
; CD 21
xchg bx, ax				; File handle (XCHG takes one less byte to encode)
mov cl, FILE_SIZE		; Bytes to write (CH is already 0 due to previous XCHG instruction)
xchg dx, si				; Exchange DX and SI (SI never changed and points to 0x100 - http://www.fysnet.net/yourhelp.htm)
mov ah, 0x40
int 0x21				; DOS interrupt 21,40 - Write To File

; AC
; CD 29
lodsb					; Load the last byte of the file in AL - was set when previously exchanging DX and SI
int 0x29				; DOS interrupt 29 - Fast Console Output

; C3
ret						; Hack - returns to address 0 which has the PSP and effectively runs DOS interrupt 20 - Terminate Program

; 34
filename: db '4'		; Maintains the filename (saves the NUL terminator since post-program chunk if full of zeros)
eof:
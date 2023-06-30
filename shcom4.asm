;
; shcom4.asm
;

; Constant - the file size
FILE_SIZE EQU (eof-$$)

; All COM programs start at 0x100
org 0x100

;
; Shell script
; Encodes to garbage commands that ultimately just zero the SP register:
;	23 21			and  sp, [bx+di]
; 	0A 63 70		or   ah, [bp+di+0x70]
;	09 2A			or   [bp+si], bp
;   09 34			or   [si], si
;	7C 65			jl   0x0170
;	78 69			js   0x0176
;	74 20			je   0x012F
;	34 00			xor  al, 0x00
;	0A 23			or   ah, [bp+di]
db '#!', 0x0A							; Empty interpreter still must be followed by "\n"
db 'cp', 0x09, '*', 0x09, '4|exit '		; Using "\t" as a separator to avoid destroying program code pointed by SI
filename:
db '4', 0								; Adding a NUL terminator (fine by bash) to reuse later in COM code
db 0x0A, '#'							; Finishing with a "\n" and a remark

;
; 91
; BA 0F 01
; B4 5B
; CD 21
xchg cx, ax				; Assign 0 to CX
mov dx, filename		; Saves the filename to create in DX (reuse data from shell script)
mov ah, 0x5B
int 0x21				; Create the file with DOS interrupt 21,5B

;
; 93
; B1 16
; 87 D6
; B4 40
; CD 21
xchg bx, ax				; File handle (XCHG takes one less byte to encode)
mov cl, FILE_SIZE		; Bytes to write (CH is already 0 due to previous assignment of 0 to CX)
xchg dx, si				; Exchange DX and SI (SI never changed and points to 0x100 - http://www.fysnet.net/yourhelp.htm)
mov ah, 0x40
int 0x21				; DOS interrupt 21,40 - Write To File

; AC
; CD 29
lodsb					; Load the last byte of the file in AL - was set when previously exchanging DX and SI
int 0x29				; DOS interrupt 29 - Fast Console Output

; CD 20
int 0x20				; DOS interrupt 20 - Terminate Program

eof:
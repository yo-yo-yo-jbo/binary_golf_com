# COM and Binary Golf
After my fun time with [Dangerous Dave](https://github.com/yo-yo-yo-jbo/dangerous_dave) I've decided to look for more opportunities to play around with Real Mode assembly.  
It's just so happens that [Binary Golf Grand Prix](https://binary.golf) is happening!  
For those of you who are unfamiliar, Binary Golf Grand Prix is a competition to generate small files that do a specific task.  
This year (2023) the task is simple: output `4` and self-copy to a file called `4`. You can do it in a shell script, Python etc.  
Obviously scripting would be easy, but I've decided to go with [COM](https://en.wikipedia.org/wiki/COM_file)!

## COM background
Why did I choose COM? Well, a few reasons:
1. As I mentioned, I wanted an opportunity to have fun with Real Mode assembly.
2. COM files do not have headers! They just get loaded to memory.
3. COM files are loaded at a predefined address (`0x100`).

## Plan of action
My plan is simple - use software interrupts (mostly [DOS API](https://en.wikipedia.org/wiki/DOS_API) that usually revolves around `int 21h`) and minimize assembly encoding. Specifically:
1. Create a file called `4`.
2. Write the contents to the file. Since we already know where to copy from (`0x100`) and how much to copy (the file size) - this should be straightforward.
3. Write one character - `4`.
4. Teminrate program.

As usual, I plan to use [NASM](https://www.nasm.us) as my Assembler of choice.

There are some nice optimizations I discovered while doing this challenge:
1. It's better to use `xchg bx, ax` than `mov bx, ax` since it's encoded as a single byte... Of course, if you don't care about `ax`.
2. The program is loaded to `0x100` immidiately after a block called [Program Segment Prefix](https://en.wikipedia.org/wiki/Program_Segment_Prefix) (or PSP for short), which contains some useful information. Unfortunately, it wasn't useful to me.
3. It's better to use `int 0x20` than `int 0x21` to temrinate the program since you don't have to set any other registers.
4. The memory after the program is filled with zeros. Since I needed the NUL terminated string `4\x00` it saved me one byte.
5. There's very good documentation regarding initial register values when your program starts running ([here](http://www.fysnet.net/yourhelp.htm)). Specifically, I used the fact that `si` is `0x100` to my benefit, and the initial value of `0xFF` assigned to `CX` had to be dealt with.
6. Interrupts generally maintain register values. I use that for my benefit.

## Code
Here's my code, followed by some explanations:

```assembly
;
; Make4.asm
;

; Fine-tunable - the file size
FILESIZE EQU (msg-$$+1)

; All COM programs start at 0x100
org 0x100

; Saves the filename to create in DX
mov dx, msg

; DOS interrupt 21,5B - Create File
pop cx					; File attributes (pops 0 as 0xFF is invalid - http://justsolve.archiveteam.org/wiki/DOS/Windows_file_attributes)
mov ah, 0x5B
int 0x21

; DOS interrupt 21,40 - Write To File
xchg bx, ax				; File handle (XCHG takes one less byte to encode)
mov cl, FILESIZE		; Bytes to write (CH is already 0)
mov dx, si				; Buffer to write (SI never changed and points to 0x100)
mov ah, 0x40
int 0x21

; BIOS interrupt 10,0E - Write character
mov ax, 0x0E34			; Character + interrupt number
int 0x10

; DOS interrupt 20 - Terminate Program
int 0x20
	
; Maintains the data and saves the NUL terminator since post-program chunk if full of zeros
msg: db '4'
```

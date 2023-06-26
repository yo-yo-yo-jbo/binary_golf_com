# COM and Binary Golf
After my fun time with [Dangerous Dave](https://github.com/yo-yo-yo-jbo/dangerous_dave) I've decided to look for more opportunities to play around with Real Mode assembly.  
It's just so happens that [Binary Golf Grand Prix](https://binary.golf) is happening!  
For those of you who are unfamiliar, Binary Golf Grand Prix is a competition to generate small files that do a specific task.  
This year (2023) the task is simple: self-copy to a file called `4` and eithet output or return 4. You can do it in a shell script, Python etc.  
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

; Constant - the file size
FILESIZE EQU (eof-$$)

; All COM programs start at 0x100
org 0x100

; Saves the filename to create in DX
mov dx, filename

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
	
; Maintains the filename (saves the NUL terminator since post-program chunk if full of zeros)
filename: db '4'
eof:
```

Let's examine it:
1. `FILESIZE` is just a constant, like `#define` in C, and lets me reuse that value later. It does not encode as any bytes on its own.
2. `org 0x100` is a directive that tells NASM to assume program is loaded at that address. It does not encode as any bytes.
3. `mov dx, msg` readies the `dx` register to save the filename to create. Note how I save one byte in `msg` - normally you'd have to add a NUL terminator with `db '4', 0`. This is a costly instruction that takes 3 bytes!
4. I use `pop cx` which takes one byte. Since the initial value of `cx` is `0xff` and since `cx` is used as the file attributes to create, I cannot use `0xff` (see [here](http://justsolve.archiveteam.org/wiki/DOS/Windows_file_attributes)). I use the fact the stack is full of zeros to effectively assign zero to `cx` - I use that fact later to save a single byte.
5. I set `ah` to be `0x5B` and call `int 21h`, which creates a file with the filename pointed by `dx` and the attributes in `cx`.
6. I use `xchg bx, ax` since I need the file handle in `bx` for the next interrupt. It's expected that the handle number is going to be `5`, but I wasn't able to use that fact to lowe the number of encoded bytes.
7. `cx` is set to the file size. Note I use the fact `ch` is already zero - therefore using `mov` on `cl` alone, which takes one less byte.
8. I need to set `dx` to `0x100`, and do so with `mov dx, si`, which takes one less byte. I use the fact `si` never got modified and it's initially `0x100`.
9. I assign `0x40` to `ah` and call the DOS interrupt `21h` again, which writes to the file handle given at `bx`. It writes the amount of bytes in `cx`, from the buffer pointed by `dx`.
10. I assign `ah` to `0x0e` and `al` to the character `4` in one go - by assigning `0x0E34` to `ax`. Then I call `int 10h` which is a [BIOS interrupt](https://en.wikipedia.org/wiki/BIOS_interrupt_call) that writes the character in `al` to the terminal.
12. I quit the program by calling `int 20h`.

The entire program takes `25` bytes - not a bad start!  
You can compile with the following command:

```shell
nasm -f bin -o MAKE4.COM make4.asm
```

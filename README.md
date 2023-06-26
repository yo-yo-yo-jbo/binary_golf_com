# COM and Binary Golf
After my fun time with [Dangerous Dave](https://github.com/yo-yo-yo-jbo/dangerous_dave) I've decided to look for more opportunities to play around with Real Mode assembly.  
It's just so happens that [Binary Golf Grand Prix](https://binary.golf) is happening!  
For those of you who are unfamiliar, Binary Golf Grand Prix is a competition to generate small files that do a specific task.  
This year (2023) the task is simple: output `4` and self-copy to a file called `4`. You can do it in a shell script, Python etc.  
Obviously scripting would be easy, but I've decided to go with [COM](https://en.wikipedia.org/wiki/COM_file)!

## Something about COM
Why did I choose COM? Well, a few reasons:
1. As I mentioned, I wanted an opportunity to have fun with Real Mode assembly.
2. COM files do not have headers! They just get loaded to memory.
3. COM files are loaded at a predefined address (`0x100`).

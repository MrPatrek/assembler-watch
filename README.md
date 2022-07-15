# assembler-watch

A watch written in the assembly language. You can **set** the desired time, after which clock will begin to work. You can also **reset** it to a new time value during its work.

## How to test it

You can check it out using [this website](https://asm-simulator-599136.netlify.app/). To do this, insert the code from the *watch.asm* file to the main input field on that website. Then, do the following:

- go to *Speed* and choose *64 kHz*
- click *Assemble* and after that *Run*

On the right side of the website you have a numpad, where you will enter your desired time value. If you want to reset time when the watch is already working, just press * and set the new desired time.

If you experience lags (e.g. more than one second is needed to change the time on watch), go to *View* and **unclick** *Memory*.

For the detailed instructions and explanation of how it works, refer to the comments inside *watch.asm* file.

# libtsprites
C++ shared library for truecolor unicode terminal sprites, effects, and animations.
Blazingly fast 2.5D parallax rendering-, extendable effects-, and animation-engine! 
OS independent. No code dependencies. RGB and HSL color support. Ideal for terminal
games, or just more interesting user interfaces.  



https://github.com/M64GitHub/libtsprites/assets/84202356/df1eb0c2-82d1-40eb-8d40-65a8c15530b8



The intention is to create a library for visual expression on `state of the art`,
`fast` `terminals`.
A well setup terminal today allows for very interesting visual experiences
and effects. This is an exploration of what can be achieved taking it to
the max.

It is assumed, that the terminal supports: UTF-8 unicode, 24 bit colors, and
is set-up with a proper monospaced font. Tests so far were done on `kitty`
on gnu/linux, the `gnome-terminal` (Ubuntu default), and `kitty` on the mac.
Those for sure work well and fast. The `cygwin terminal` on Windows (tested
on Windows 10) also does the job, but is a bit slow. `iTerm2` on the mac 
"works" (technically), but has shown to be very slow.  
A note about nerd-fonts (https://www.nerdfonts.com/font-downloads)
shall be given here as well.  

Work in progress ...

## MAIN CONCEPT

The whole lib is based on the concept of `blocks` ('▄' or '▀') forming
`sprites` (various sorts of) placed on `screens`, and a `rendering engine`
to glue everything together.

- Please note upfront: all the components are independent, and optional to
use.You need no screen screen, or anything else than (any type of) `sprite`
if you just want to display some graphics. (see [Basic Usage](#basic-usage))

"Everything is a sprite". Everything you can place on the screen and see is
any type of a sprite. Even text, or shapes of ASCII characters. Every type 
of sprite has `frames`, `animations`, `effects`, and is moveable.

`screens` support clipping, effects, screens inside of screens ("windows"), 
multiple screens next to eachother, and can be moved, too.

The `rendering engine` glues all together, and the main screen(s) can be
displayed by the terminal.

The coordinate-system by default uses measurements in blocks. Shapes formed
of `blocks` are called `regular sprites` - the code representation would be
a `TSprite`. `TSprites` can be moved freely in the coordinate-system, while
anything "character-based" like strings or shapes of ASCII/UTF-8 characters
only in Y-steps of 2. The Z-coordinate can be used to select flat `layers`
for output, bringing objects closer to the fore- or backgound, for 
parallax effects, etc.

A special case: with a bit of trickery, completely smooth (almost pixelwise)
movements of 2 stacked blocks ('█') can be achieved: in 1/8 fraction steps of a 
characters dimension. Those "double blocks" are called `soft-blocks`.
They can be smoothly moved only: in either the X- or the Y-coordinate, not
both at the same time.

With mulitple `soft-blocks` and a bit of trickery, lines of arbitrary length
are possible: '██▌'. Such lines share the movement properties of
a `soft-block` and are called `soft-lines`.  
Soft-blocks and soft-lines can be used for a very limited usage-set
due to their rather "big" visual blockyness of a full character. But with
their interesting possibility to move them "freely" and "smooth", some nice
special-effects are possible, and they are ideal for `block-based games`,
`progress-bars`.

These are just the most basic ideas. A multitude of types of sprites exists
for implementing anything visually as fast and as simple as possible.

### Summary of Main Principles, Shapes and Objects

 - `blocks`: half characters. Have a color or can be transparent: '▄' or '▀'
 are individual blocks. Shapes of blocks are called `regular sprites` or
 `TSprites`. You can think of them as pure "pixel" based sprites, where a
pixel is represented by a block.
 - `regular characters`:  Shapes made of ASCII/UTF-8 characters can be built
and are called `ascii-sprites` or `ASprite`. Of course you can include block
characters within them, too. But you can't zoom these sprites, or rotate, etc.
 - `regular strings`: to work with text-strings / line-text, another sprite
class called `SSprite` (`string sprite`) exists. This can be used to place/fade
text onto the screen, create spinners (1 character animations), and such.
 - `soft-blocks` and `soft-lines`: leveraging UTF-8 block characters for
 pixelwise smooth (constrained) movements and positioning.  
The UTF-8 block characters enables to form (virtual) 8x8 blocks '█', that
can be moved "pixelwise": '▐▌'. This is achieved by using 2 characters and
specific combinations of foreground and background colors of the supported
block character-set. A soft block is visually always (virtual) 8x8 pixels in
 dimension.  
The same concept also can be used to form lines of arbitrary length in
virtual pixels: '▐█▌', '██▌'. A special type of sprites take leverage from
these shapes and is called `LSprite` or `line-sprite`.
 - `frames`: each sprite can hold multiple shapes of itself: for creating
animations, slices, specific color-fading, or different rotations of a moving
player figure for example.
 - `animations` - set of frames combined with relative (movement) coordinates
 - `layers` - Z-coordinate
 - `screen` - the full work area (clipping) or used as (sub-) windows

The different types of sprites exist to help in the realisation of ideas.
Each sprite type has it's own capabilities, pro's and con's.

### Main Classes / Structs for:

 - Sprites - TSprite (pixel), LSprite (lines), ASprite (ASCII), SSprite (string)
 - RGB-, HSV-colors and -palletes
 - Screen
 - Effects
 - Animations
 - 2.5D Parallax Render Engine / Render-Surface

## EXAMPLE CODE
For getting started quickly, example code is provided in the subfolder
`examples/`. They all have their own Makefile and include the library code
directly, without the need of compiling the library as a shared object.
You can use them as a starter for your own ideas, and copy/extend them
without ever building the shared library, or have the need to link against
it, if you prefer.

### Basic Usage
How to use the the `TSprite` object. How to get some graphics onto the screen.

Getting started is simple. The two most basic methods of `TSprite` are used
in this little "hello world" example: `ImportFromFile()`, and `Print()`.

Sprite graphics can be created with help of the `catimg` utility
(https://github.com/posva/catimg). Simply redirect it's output to a file.
You can also take any "*.unicode" file from the resource folder to test.

When a `TSprite` is imported, the graphic data is being parsed, normalized,
and rewritten into the internal datastructures. These prepare for fast
movement on screen, and for applying effects to the graphic data more
efficiently.

`Print()`: please note: the Print() method is the fastest one to print a
sprite directly on the terminal. It does not handle transparency and it is
comletely unaware of any coordinates, layers and other elements we will
see used in later examples. 

```C++
#include <stdio.h>
#include "../../include/tsprites.hpp"
#include "../../include/tsutils.hpp"

int main(int argc, char **argv)
{
    TSprite S;                    // create a TSprite object S

    // check cmdline for filename
    if (argc != 2) { printf("Usage: ./test <filename>\n"); return 1; }

    char *file_name = argv[1];    // get filename from cmdline

    term_clear();                 // clear the screen
    printf("hello world!\n");
    S.ImportFromFile(file_name);  // import catimg redirected output file
    S.Print();                    // print the sprite!

    return 0;
}
```
```bash
./test ../../resources/demo7_188.unicode
```

![image](https://github.com/M64GitHub/libtsprites/assets/84202356/d61df269-0c09-497f-a057-0598cca94aa0)

### Simple Movement, manual Animation
Here the convenience functions `term_init()` and `term_close()` are introduced.
They will clear the terminal and restore the screen and cursor afterwards.

Also two new `SSPrites` ("String Sprites") are introduced: `S1` for a simple 
(single-frame) string, and `S2` for some animated spinners.
The spinner S2 takes an array of strings, the arrays's length (number of 
sprite frames), and a `rgb_color` as input parameters for the constructor. 
The other one just a regular (char *) string.

The x-movement of the sprites is again done simply by moving the cursor, and 
printing the sprites like in the example above. This is one way to easily
position a sprite. `Print()` just prints the sprite where the cursor currently
stands.  
As you can see, `S1` is printed via `PrintUncolored()`. This is a method specific
to string-sprites: the color information is completely discarded on output, and 
the default terminal color is used.

Since S1 and S2 are not being "moved" (just printed where the cursor stands)
they are also not cleared from the old to the new position. This makes up to a
nice effect you can see in the video below.

For convenience, every Sprite class has 3 `counters` and 3 `thresholds` builtin.
This can come in handy when used in some synced effects for example, and 
can save you from defining a lot of temporary variables.

The goal of this example is to show, that without further knowing any other 
concept than printing / printing of a frame of a sprite, you can manually
add calls to a sprite's Print Routine and easily do some basic animations,
and already import even little animations into your own terminal based
application. It is at least advised to hide the cursor and restore it 
afterwards, while printing a sprite in such cases. Convenience functions
`cursor_off()` and `cursor_on()` are therefor provided, too.

```C++
#include <math.h>   // for sin()
#include <unistd.h> // for usleep()
#include <stdio.h>  // for printf()
#include "../../include/tsprites.hpp"
#include "../../include/tsutils.hpp"

int main(int argc, char **argv)
{
    char *spinners[] = { // array of strings for the spinner sprite below
                        (char*) " - ▁   SSprite ", 
                        (char*) " \\ ▂ ░ SSprite ",
                        (char*) " | ▃ ▒ SSprite ",
                        (char*) " / ▄ ▓ SSprite ",
                        (char*) " - ▅ █ SSprite ",
                        (char*) " \\ ▆ ▓ SSprite ",
                        (char*) " | ▇ ▒ SSprite ",
                        (char*) " / █ ░ SSprite ",
    };

    rgb_color spinners_color = { 0x9C, 0x41, 0xdE }; // R, G, B

    TSprite TS; // create TSprite and load the graphics data
    TS.ImportFromFile((char*)"../../resources/demo7_188.unicode");

    SSprite S1( (char *)"_.:[M64]:._" );       // create a string-sprite
    SSprite S2( spinners, 8, spinners_color ); // create a string sprite,
                                               // add 8 frames "animation"

    TS.counter1    =  50; // start value for x-movement while loop
    TS.threshhold1 = 850; // end   value for x-movement while loop

    term_init();          // clear terminal

    while(TS.counter1 < TS.threshhold1)
    {
        TS.counter1++;
        cursor_home();    // move the cursor to topleft in terminal
        int x = 10 + 10*(sin( ((TS.counter1 % 100)/100.0)*6.28 ))-1;

        cursor_right(x);  // position TS
        TS.Print();       // and print it
        printf("\n");

        cursor_right(90 + x/4); // position S1
        S1.PrintUncolored(); // prints in default terminal color

        // animate spinners by selecting frame to be printed: S2.frame_idx
        cursor_left (90 + x/4); // position S2
        if(!(TS.counter1 % 8)) S2.frame_idx = (S2.counter1++ % 8);
        S2.Print();             // print it

        usleep(1000 * 10);// wait 10 milliseconds
    }
    
    term_close();         // restore terminal 
    return 0;
}
```

https://github.com/M64GitHub/libtsprites/assets/84202356/90d4a9d3-815f-405c-beaa-802bda05cc45


## BUILD
You can build the library along with a simple test program by running
```bash
make
```
The shared library can then be found in the `lib/` folder.
The test executable ('test') will be created in the current path.
You can run it via
```bash
LD_PRELOAD=./lib/libtsprites.so ./test
```
To build the library only:
```bash
make lib
```
For building your own applications using libtsprites 
 - include the`<PATH TO include>/tsprites.hpp` in your code
 - optionally add `-I<PATH TO include>` to your compiler-flags
 - add `-ltsprites` and `-L<PATH TO .so file>` in the linking step

The most easy way to do all this is to copy the library to `/usr/lib/`.
```bash
sudo cp lib/libtsprites.so /usr/lib
```
You then need not set LD_PRELOAD for running your program, and are done by just
including the header and adding `-ltsprites` to your linker flags.

## INSTALL
Gnu/linux systems:
```bash
sudo make install
```
Copies the shared lib into `/usr/lib/`, and the include files into `/usr/include/`.

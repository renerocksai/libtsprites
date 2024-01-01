#include <stdio.h>
#include <math.h>
#include <unistd.h>
#include "../../include/tsprites.hpp"

int main(int argc, char **argv)
{
    char *spinner[] = { 
                        (char*) " - ▁   SSprite ", 
                        (char*) " \\ ▂ ░ SSprite ",
                        (char*) " | ▃ ▒ SSprite ",
                        (char*) " / ▄ ▓ SSprite ",
                        (char*) " - ▅ █ SSprite ",
                        (char*) " \\ ▆ ▓ SSprite ",
                        (char*) " | ▇ ▒ SSprite ",
                        (char*) " / █ ░ SSprite ",
    };

    rgb_color spinner_color = { 0x9C, 0x41, 0xdE };

    TSprite S;
    SSprite S2((char *)"_.:[M64]:._");
    SSprite S3(spinner, 8, spinner_color);

    unsigned int tick = 50;
    int char_tick = 0;
    unsigned int maxtick = 850;

    S.ImportFromFile((char*)"../../resources/demo7_188.unicode");

    board_init();

    // --

    while(tick < maxtick)
    {
        tick++;
        int x = 10 + 10*(sin( ((tick % 100)/100.0) * 6.28  ));
        cursor_home();
        cursor_right(x-1);
        S.Print();

        cursor_right(90);
        cursor_right((x-1)/4);
        S2.PrintUncolored();

        // spinner
        cursor_home();
        cursor_down(15);
        cursor_right(5);
        if(!(tick % 8)) S3.frame_idx = (++char_tick % 8);
        S3.Print();

        usleep(1000 * 10);
    }

    // --

    
    board_close();

    return 0;
}

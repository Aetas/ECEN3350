/* -------------------------------------------- */
/* Derek Prince                                 */
/* ECEN 3350: Programming Digital Systems       */
/* Assignment 4 - Question 1.                   */
/* Scrolling things and inverting patterns      */
/* -------------------------------------------- */

/* ------------------------------------------------------------------------------ */
/* MIT License                                                                    */
/*                                                                                */
/* Copyright (c) 2017 Derek Prince                                                */
/*                                                                                */
/* Permission is hereby granted, free of charge, to any person obtaining a copy   */
/* of this software and associated documentation files (the "Software"), to deal  */
/* in the Software without restriction, including without limitation the rights   */
/* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      */
/* copies of the Software, and to permit persons to whom the Software is          */
/* furnished to do so, subject to the following conditions:                       */
/*                                                                                */
/* The above copyright notice and this permission notice shall be included in all */
/* copies or substantial portions of the Software.                                */
/*                                                                                */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     */
/* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       */
/* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    */
/* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         */
/* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  */
/* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  */
/* SOFTWARE.                                                                      */
/* ------------------------------------------------------------------------------ */

/* To be honest, this program started out great and turned to garbage real    */
/* quick. I needed way more variables than I originally thought - largely     */
/* due to me not planning for the pattern bit and applying bandaids to fit it.*/
/* Doing it again, I would have just taken the extra instructions to use      */
/* only a few registers for dedicated purposes and thrown the things like     */
/* loop limits in an array instead of bullshit registers.                     */
/* Still, it works. Just don't try to link to it.                             */

/* This program utilizes registers heavily.                                   */
/* Many of these registers are set every time they are called - begging the   */
/* question as to why am I using so many.                                     */
/* As this is a stand-alone program, using different registers helps keep     */
/* things straight (but would be horrible to function call to comparatively.) */
/* L'indécis ---------------------------------------------------------------- */
/* r20 -> timer root address                                                  */
/* r2 -> 7-seg disp. address                                                  */
/* r3 -> timer status reg.                                                    */
/* r4 -> loop counter                                                         */
/* r5 -> display register                                                     */
/* r6 -> display buffer                                                       */
/* r7 -> buffer root                                                          */
/* r8 -> buffer mask                                                          */
/* r9 -> patterns                                                             */
/* r10 -> flashy bit index                                                    */
/* r12 -> xor mask for flipping                                               */
/* r17 -> Pattern loop length                                                 */
/* r18 -> Pattern restart loop length                                         */
/* r19 -> stores display length.                                              */
/* r21 -> stores 4 to compare to. why is there no beqi???                     */
/* Whoopsie Registers.                                                        */
/* r11 -> buffer counter. I didn't want this but that's how it is.            */
/* r15 -> Messages Reg.                                                       */
/* r16- > Patterns Reg.                                                       */
/* -------------------------------------------------------------------------- */

/* 50MHz timer.                         */
/* 0.5s -> 50MHz * 0.5 = 25M            */
/* 25M = 0x017D|7840                    */
/*         HIGH| LOW                    */

.text
.global _start

_start:
movia r20, 0x10002000  /* Timer Root    */
movia r2, 0x10000020   /* Display Root  */
movia r15, MESSAGE
movia r16, PATTERNS
/* ======================================================================= */
/*                                TIMER SETUP                              */
/* ======================================================================= */
/* start by setting timer countdown length                                 */
ori r3, r0, 0x017D
stwio r3, 12(r20)   /* high */
ori r3, r0, 0x7840
stwio r3, 8(r20)    /* low  */
/* set timer to continuous countdown.                                       */
/* This makes the interval regular regardless of executable instructions.   */
/* could be bad if execution takes more than 500ms. Which it won't.         */
movia r3, 0b110
stwio r3, 4(r20)

/* ======================================================================== */
/*                     TIMER LOOP AND MESSAGE DISPLAY                       */
/* ======================================================================== */
/* I need a timer loop to do the busy-wait                                  */
/* and a buffer check and a display section                                 */
movi r19, 20        /* message length                         */
movi r21, 4         /* buffer condition                       */
/* Display Loop Start ----------------------------------------------------- */
DISP_LOOP:
ori r4, r0, 0b0           /* counter                 */
ori r11, r0, 4            /* buffer counter          */
ldw r5, 0(r15)            /* initial setup           */

/* Timer Loop Main -------------------------------------------------------- */
CHECK_TIMER:
ldwio r3, 0(r20)
andi r3, r3, 0b1
beq r3, r0, CHECK_TIMER   /* loop until timer completes. */
ori r13, r0, 0b110
stwio r13, 0(r20)
bge r4, r19, FLASHY_BIT

/* Need-New-Buffer Check -------------------------------------------------- */
bne r11, r21, NO_NEW_BUFFER/* this is only 0 when after 4 passes            */
add r7, r4, r15            /* generate index address                        */
addi r7, r7, 5             /* I want to start grabbing from next address    */
ldwio r6, 0(r7)
ori r11, r0, 0b0           /* reset buffer counter                          */
NO_NEW_BUFFER:

/* Write, Shift, and Mask Display Register -------------------------------- */
stwio r5, 0(r2)           /* write to displays                     */

slli r5, r5, 8            /* shift two hex keys -> one 7-seg disp  */
addi r11, r11, 1          /* increment shitty buffer index         */
srli r8, r8, 8            /* set r8 to 0 */
andi r8, r6, 0x7F000000   /* mask disp. buffer                     */
srli r8, r8, 24           /* Shift to set in the right place.      */
slli r6, r6, 8            /* shift display buffer for next pass    */

or r5, r5, r8             /* place two hex chars from buffer into disp. reg */
addi r4, r4, 1            /* increment r4 */

blt r4, r19, CHECK_TIMER  /* break if more message to display      */

/* ======================================================================== */
/*                              PATTERN DISPLAY                             */
/* ======================================================================== */
/* set-up ----------------------------------------------------------------- */
ldw r9, 0(r16)    /* load first pattern        */
or r5, r0, r9     /* set the display reg to it */
addi r17, r0, 6
addi r18, r0, 12
addi r10, r0, 1  /* pattern index. r4 is allowing us to skip down here     */

FLASHY_BIT:
/* Fetch New Pattern Cond. ------------------------------------------------ */
bne r10, r17, SAME_PATTERN
ldw r9, 4(r16)            /* grab new pattern          */
or r5, r0, r9             /* put it in display reg.    */
            /* set condition limit to 12 */

SAME_PATTERN:
stw r5, 0(r2)             /* Display before flip             */
/* ~FlipBobaire ----------------------------------------------------------- */
movia r12, 0x7F7F7F7F     /* 0x7F... avoids flipping the dot */
xor r5, r5, r12

addi r10, r10, 1          /* increment              */
blt r10, r18, CHECK_TIMER /* Not done with patterns */
bge r10, r18, DISP_LOOP   /* look at it go          */


/* ======================================================================== */
/*                                   DATA                                   */
/* ======================================================================== */
.data
MESSAGE:
  .word 0x00000000, 0x76793838, 0x3F007F3E, 0x71716D40, 0x40400000, 0x0
  /* H E L L     O _ B U     F F S -     - - _ _  + two more spaces        */
  /* this could be done without storing spaces. But oh well.               */
PATTERNS:
  .word 0x49494949, 0x7F7F7F7F
  /* Pattern B is just the inverse of pattern A - no need to store         */
  /* Same is true of Pattern C and the blank (w/ the exception of the dot) */

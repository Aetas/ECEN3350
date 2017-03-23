/* -------------------------------------------- */
/* Derek Prince                                 */
/* ECEN 3350: Programming Digital Systems       */
/* Assignment 4 - Question 2.                   */
/* Scrolling things and reverse patterns        */
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


/* The pushbuttons are awkward without interrupts.                            */
/* There's no magical polling rate to make it only register one press while   */
/* not missing it. Otherwise this program is lovely successor to it's shitty  */
/* brother, problem 1.                                                        */

/* Stack -------------------------------------------------------------------- */
/*                                                                            */
/* |           ^ Old Stack ^             |                                    */
/* ---------------------------------------                                    */
/* | fp ->        old_fp                 | <- probably not needed.            */
/* ---------------------------------------                                    */
/* |            Timer counter            | - 4(fp)                            */
/* ---------------------------------------                                    */
/* |         Current Pattern No.         | - 8(fp)                            */
/* ---------------------------------------                                    */
/* |             Display hex             | -12(fp)                            */
/* ---------------------------------------                                    */
/* |             Buffer hex              | -16(fp)                            */
/* ---------------------------------------                                    */
/* | sp ->   Button pressed (bool)       | -20(fp)                            */
/* ---------------------------------------                                    */

.text
.global _start
_start:
/* ========================================================================== */
/*                                    SETUP                                   */
/* ========================================================================== */
/* Stack Setup -------------------------------------------------------------- */
/* things are referenced from frame pointer because I'm going to move the     */
/* stack pointer if I need more space. I don't want to have to change         */
/* every offset if I just need one more word of space.                        */
addi sp, sp, -4
stw fp, 0(sp)
add fp, r0, sp   /* adjust frame pointer                  */
addi sp, sp, -20 /* adjust as needed. Or don't. Be crazy. */

or r2, r0, r0
stw r2, -4(fp)   /* Set timer initial                     */

/* Addresses ---------------------------------------------------------------- */
movia r4, 0x10002000   /* Timer Root      */
movia r5, 0x10000020   /* Display Root    */
movia r6, 0x10000050   /* Pushbutton Root */

/* Set Initial Pattern ------------------------------------------------------ */
add r2, r0, r0  /* set the initial pattern to the first one. r2=4 would be p2 */
stw r2, -8(fp)  /* store pattern number                                       */
movia r2, PATTERNS
ldw r2, 0(r2)
stw r2, -16(fp) /* store pattern in buffer mem. location                      */
or r2, r0, r0
stw r2, -12(fp) /* store initial 0's in disp. mem. location                   */

stwio r2, 0(r5) /* This is just initial so display can be after shift loop    */

/* ========================================================================== */
/*                                 TIMER SETUP                                */
/* ========================================================================== */
/* countdown length set ----------------------------------------------------- */
/* countdown length of 25ms.      */
/* count to 1,250,000; 0x001625A0 */
ori r2, r0, 0x16
stwio r2, 12(r4)   /* set high bits */
ori r2, r0, 0x25A0
stwio r2, 8(r4)    /* set low bits  */
/* continuous countdown ----------------------------------------------------- */
movia r2, 0b110    /* enables continuous and run */
stwio r2, 4(r4)

/* ========================================================================== */
/*                                 TIMER CHECK                                */
/* ========================================================================== */
/* I need a count variable to check the pushbutton every cycle */
/* but shift the displays every 10 cycles (0.5 sec)            */
/* storing this stuff in memory might not be ideal since this  */
/* code runs so often. It's the busy-wait loop.                */
/* Update: did it anyway                                       */
TIMER_CHECK:
ldw r7, -4(fp)                                     /* r7 -> timer counter     */
ldwio r8, 0(r4)                                    /* r8 -> timer status reg  */
andi r8, r8, 0b1   /* mask the timeout signal */
ori r2, r0, 0b110
stwio r2, 0(r4)   /* reset timer              */
/* if signal is 1, increment count and check pushbutton        */
beq r8, r0, TIMER_CHECK
addi r7, r7, 1    /* increment                */
stw r7, -4(fp)    /* save                     */
/* if r7 = 10, shift displays                 */
/* else (then) check push-buttons             */
addi r7, r7, -10

/* ========================================================================== */
/*                              PUSH-BUTTON CHECK                             */
/* ========================================================================== */
ldwio r8, 0(r6)                                    /* r8 -> pb data mask      */
andi r8, r8, 0b1100 /* Don't bother with the reset button   */
/* if nothing, skip to end. Else handle button press.       */
beq r8, r0, PUSHBUTTON_END
/* Update Pattern ----------------------------------------------------------- */
/* if pattern 1, switch to second pattern. Else switch second to first        */
ldw r8, -8(fp)                                     /* r8 -> pattern no.       */
beq r8, r0, SECOND_PATTERN
or r8, r0, r0            /* set to first pattern no.      */
br PATTERN_SWAP_END
SECOND_PATTERN:
addi r8, r8, 4           /* set to second pattern no.     */
PATTERN_SWAP_END:
stw r8, -8(fp)           /* store updated pattern no.     */
ori r8, r0, 0b1          /* 32-bit bool coming through    */
stw r8, -20(fp)          /* store 'fetch new buffer' bool */
PUSHBUTTON_END:
blt r7, r0, TIMER_CHECK  /* if no display update          */
/* note: r7 was set in TIMER CHECK section */

/* ========================================================================== */
/*                                DISPLAY SHIFT                               */
/* ========================================================================== */
DISPLAY_SHIFT:
ldw r7, -4(fp)                                     /* r7 -> timer counter     */
or r7, r0, r0   /* set back to zero   */
stw r7, -4(fp)  /* save it            */

/* Check Buffer State ------------------------------------------------------- */
ldw r7, -20(fp)                                    /* r7 -> new buffer bool   */
/* !if (new buffer bool) { grab other pattern } */
beq r7, r0, NO_NEW_BUFFER
or r7, r0, r0                 /* set bool to 0 before ditching */
stw r7, -20(fp)               /* save bool to note complete    */
ldw r7, -8(fp)                /* current patt. no.             */
movia r8, PATTERNS            /* patterns root                 */
add r8, r7, r8                /* get pattern offset            */
ldw r7, 0(r8)                 /* grab updated pattern          */
stw r7, -16(fp)               /* update pattern in mem.        */
or r7, r0, r0
stw r7, -12(fp)               /* update display to nulls       */
NO_NEW_BUFFER:
ldw r7, -12(fp)                                    /* r7 -> display reg       */
ldw r8, -16(fp)                                    /* r8 -> buffer reg        */
ldw r9, -8(fp)                                     /* r9 -> pattern no.       */

/* Update Display State ----------------------------------------------------- */
/* I'm just going to make this into a circular buffer so that it does not     */
/* require a counter to tell the buffer to fill again like that filthy        */
/* sibling, problem 1. The buffer is very much the master/leader while the    */
display is follower/slave. Buffer is ahead.                                   */

/* ~~~ Behold, witchcraft ~~~ */
/*  (づ｡◕‿‿◕｡)づ *:･ﾟ✧ ✧ﾟ･: */
beq r9, r0, SCROLL_LEFT
SCROLL_RIGHT:
/* Deal with Display      */
andi r9, r7, 0x7F         /* extract bits that will otherwise be lost  */
slli r9, r9, 24           /* position bits with empty bits in disp.    */
srli r7, r7, 8            /* scroll the display right                  */

/* Deal with buffer       */
andi r10, r8, 0x7F        /* same deal as disp. mask up but for buffer */
slli r10, r10, 24         /* position bit mask                         */
srli r8, r8, 8            /* scroll the buffer right                   */

br UPDATE

SCROLL_LEFT:
/* Deal with Display      */
andi r9, r7, 0x7F000000   /* extract bits that will otherwise be lost  */
srli r9, r9, 24           /* position bits with empty bits in disp.    */
slli r7, r7, 8            /* scroll the display left                   */

/* Deal with buffer       */
andi r10, r8, 0x7F000000  /* same deal as disp. mask up but for buffer */
srli r10, r10, 24         /* position bit mask                         */
slli r8, r8, 8            /* scroll the buffer left                    */

UPDATE:
or r7, r7, r10            /* place next pattern in                     */
or r8, r8, r9             /* samesies (for buffer)                     */

stwio r7, 0(r5)           /* Update display                            */
/* Update Memory ------------------------------------------------------------ */

stw r7, -12(fp)
stw r8, -16(fp)

br TIMER_CHECK

/* This code never actually reaches this point. But I might as well.          */

ldw fp, 0(fp)
addi sp, sp, 20

/* ========================================================================== */
/*                                    DATA                                    */
/* ========================================================================== */
.data
PATTERNS:
  .word 0x79494949, 0x4949494F

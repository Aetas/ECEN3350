/* -------------------------------------------- */
/* Derek Prince                                 */
/* ECEN 3350: Programming Digital Systems       */
/* Assignment 5 - Scrolling Interrupts          */
/* 'We'll get there fast and then take it slow' */
/*  -Kermit the Frog on Kokomo                  */
/*    -Not to be confused with The Beach Boys   */
/* -------------------------------------------- */

/* ----------------------------------------------------------------------------- */
/* MIT License                                                                   */
/*                                                                               */
/* Copyright (c) 2017 Derek Prince                                               */
/*                                                                               */
/* Permission is hereby granted, free of charge, to any person obtaining a copy  */
/* of this software and associated documentation files (the "Software"), to deal */
/* in the Software without restriction, including without limitation the rights  */
/* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     */
/* copies of the Software, and to permit persons to whom the Software is         */
/* furnished to do so, subject to the following conditions:                      */
/*                                                                               */
/* The above copyright notice and this permission notice shall be included in    */
/* all copies or substantial portions of the Software.                           */
/*                                                                               */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    */
/* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      */
/* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   */
/* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        */
/* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, */
/* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE */
/* SOFTWARE.                                                                     */
/* ----------------------------------------------------------------------------- */

/**I think I have too many comments for un-color-formatted code               */
/*  Other than that, it runs great. The double input business is annoying but */
/*  the patch solution would be just as irritating. It's a harmless 'feature' */
/* Program starts scrolling at 200ms and gains 50ms for every B2 press and    */
/*  loses 50ms for every B1 press. B0 is hardware reset.                      */
/* Message is static so the actual memory that stores the message doubles duty*/
/*  as the circular buffer.                                                   */
/* I/O addresses are stored in global mem for legibility, not quick execution */
/* Interrupts enabled on timer and pushbuttons.                               */
/* Timer ISR handles the displays                                             */
/* Pushbutton ISR handles timer count length and LED readout                  */

  .text
  .global _start
  _start:

/* the stack is only set up in the case that this program is called           */
/* externally considering it will never break free of idle and return,        */
/* it seems stupid but... whatever                                            */
/* ========================================================================== */
/*                                 STACK SETUP                                */
/* ========================================================================== */
/* Stack -------------------------------------------------------------------- */
/*                                                                            */
/* |           ^ Old Stack ^             |                                    */
/* ---------------------------------------                                    */
/* |                 r3                  |  8(sp)                             */
/* ---------------------------------------                                    */
/* |                 r2                  |  4(sp)                             */
/* ---------------------------------------                                    */
/* | sp ->           ra                  |  0(sp)                             */
/* ---------------------------------------                                    */

  addi sp, sp, -12
  stw ra, 0(sp)
  stw r2, 4(sp)
  stw r3, 8(sp)

/* ========================================================================== */
/*                                 TIMER SETUP                                */
/* ========================================================================== */
/* countdown length set ----------------------------------------------------- */
/* countdown length of 200ms. +- 50ms for each button press */
/* count to 10,000,000; 0x0098 9680                         */
  movia r3, TIMER
  ldw r3, 0(r3)      /* load address */
  ori r2, r0, 0x98
  stwio r2, 12(r3)   /* set high bits */
  ori r2, r0, 0x9680
  stwio r2, 8(r3)    /* set low bits  */
/* continuous countdown and interrupt --------------------------------------- */
  movia r2, 0b111    /* start = 1, continuous = 1, interrupt enable = 1 */
  stwio r2, 4(r3)

/* ========================================================================== */
/*                            PUSHBUTTON INTERRUPTS                           */
/* ========================================================================== */
  movia r2, PUSHBUTTON
  ldw r2, 0(r2)      /* I forgot that these just hold the addresses */
  movi r3, 0b0110    /* 0-bit is NIOS II reset.        */
  stwio r3, 8(r2)    /* interrupt mask reg is 8-offset */

/* ========================================================================== */
/*                              ENABLE INTERRUPTS                             */
/* ========================================================================== */
/* enable ienable bits ------------------------------------------------------ */
/* Need timer and pushbuttons */
  movi r2, 0b011     /* timer -> level 0. pushbutton -> level 1           */
  wrctl ienable, r2

/* enable status PIE bit ---------------------------------------------------- */
  movi r2, 0b1
  wrctl status, r2   /* it feels wrong to overwrite the old data but the  */
                     /* Altera example program doesn't read+modify+write  */
                     /* soooo... Oh well?                                 */

/* ========================================================================== */
/*                                DISPLAY SETUP                               */
/* ========================================================================== */
/* load initial state to displays ------------------------------------------- */
  movia r2, DISPLAY
  ldw r2, 0(r2)      /* load display address   */
  stwio r0, 0(r2)    /* initials are 0. Always */
/* Set up display memory ---------------------------------------------------- */
/* This is required because the board seems to want to set random garbage in  */
/* my memory location for JUST THIS LOCATION. Even if I set an offset of 400  */
  movia r2, MESSAGE
  ldw r2, 0(r2)     /* load message base address. */
  movia r3, 0x00000000 /* first pattern  */
  stw r3, 0(r2)
  movia r3, 0x76793838 /* second pattern */
  stw r3, 4(r2)
  movia r3, 0x3F007F3E /* third pattern  */
  stw r3, 8(r2)
  movia r3, 0x71716D40 /* fourth pattern */
  stw r3, 12(r2)
  movia r3, 0x40400000 /* fifth pattern  */
  stw r3, 16(r2)

/* ========================================================================== */
/*                                LED INITIALS                                */
/* ========================================================================== */
/* This will be maintained in the pushbutton handler  */
  movia r2, LEDS
  ldw r2, 0(r2)          /* load led address */
  movia r3, 0b00010000   /* leading 0's are for illustrative purposes         */
  stwio r3, 0(r2)        /* push to LEDS     */

IDLE:
  br IDLE

/* Restore stack ------------------------------------------------------------ */
  stw ra, 0(sp)
  stw r2, 4(sp)
  stw r3, 8(sp)
  addi sp, sp, -12
  ret

/* ========================================================================== */
/*                                    DATA                                    */
/* ========================================================================== */
  .data
/* These are global so that the ISR/handlers can use the base addresses. */
/* Avoids save+load ~twice per call                                      */
/* A more memory efficient way would be to just hardcode the addresses   */
/* each time. But I have the space and I prefer being able to read my    */
/* code                                                                  */
  .global MESSAGE
MESSAGE:
  /*    0           4           8           C           10   */
  .word 0x00000000, 0x76793838, 0x3F007F3E, 0x71716D40, 0x40400000
  /* (4 leading spaces) '    HELLO BUFFS---' (18 characters) */

  .global TIMER
TIMER:
  .word 0x10002000

  .global PUSHBUTTON
PUSHBUTTON:
  .word 0x10000050

  .global LEDS
LEDS:
  .word 0x10000010

  .global DISPLAY
DISPLAY:
  .word 0x10000020

.end

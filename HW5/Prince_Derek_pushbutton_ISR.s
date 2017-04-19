/* -------------------------------------------- */
/* Derek Prince                                 */
/* ECEN 3350: Programming Digital Systems       */
/* Assignment 5 - Scrolling Interrupts          */
/* Pushbutton ISR                               */
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

/* Mini Stack --------------------------------------------------------------- */
/*                                                                            */
/* |           ^ Old Stack ^             |                                    */
/* ---------------------------------------                                    */
/* |                 r10                 |  12(sp)                            */
/* ---------------------------------------                                    */
/* |                 r9                  |  8(sp)                             */
/* ---------------------------------------                                    */
/* |                 r8                  |  4(sp)                             */
/* ---------------------------------------                                    */
/* | sp ->           ra                  |  0(sp)                             */
/* ---------------------------------------                                    */

/* -Pushbutoton ISR is responsible for changing the timer counter value       */
/* as well as changing the speed LEDs display state                           */
/* -If both pushbutton bits are high, probably shift to the side with more    */
/* real estate.                                                               */

/* the timer has to be stopped before changing the start number */

  .global PUSHBUTTON_ISR
PUSHBUTTON_ISR:
/* Setup stack -------------------------------------------------------------- */
/* I don't know where the program was interrupted and only r8 was saved in    */
/* the exception handler                                                      */
  addi sp, sp, -20
  stw ra, 0(sp)
  stw r8, 4(sp)
  stw r9, 8(sp)
  stw r10, 12(sp)

/* Get a grip --------------------------------------------------------------- */
  movia r8, PUSHBUTTON /* Pushbutton root      */
  ldw r8, 0(r8)        /* load PB root address */
  ldwio r9, 12(r8)     /* read edge register   */
  stwio r0, 12(r8)     /* clear interrupt      */

CHECK_BOTH_KEYS_PRESSED:
  andi r8, r9, 0b100   /* and with edge register */
  srli r8, r8, 1       /* shift right one to align with next button */
  and r8, r8, r9       /* this is only gt r0 if both were flagged   */

  beq r8, r0, CHECK_KEY1 /* if not both, check individual cases   */
                         /* the previous part could have used     */
                         /* more registers to skip masking but... */
                         /* oh well.                              */
/* Both keys pressed -------------------------------------------------------- */
  /* else */

  /* I used to have the default behavior for simultaneous button presses      */
  /* be to shift the speed towards the side with more real estate (as in,     */
  /* if it's faster than center speed, slow down and vice versa -- erring     */
  /* towards faster if it is center) but the board would catch double-double  */
  /* inputs and shift the reverse direction immediately. Not so helpful.      */
  /* Long story short, it's now considered an input error and skips it.       */

  /* UPDATE: The program actually thinks it's two separate inputs.            */
  /* The first one is when the first button is pushed, and the second one is  */
  /* when the second button is pushed (while both of them are still down)     */
  /* this creates the bounce no matter what since I can't out-clock the FPGA  */
  /* and press both buttons down within 20ns. And a 'rejection timer' (based  */
  /* off of clock cycles) would be super ugly. So I'm just going to leave it. */

  movia r8, LEDS      /* LEDs root                */
  ldw r8, 0(r8)       /* load LED address         */
  ldw r9, 0(r8)       /* get LEDs state           */
  movi r10, 0b10000   /* this is the middle value */
  ble r9, r10, SPEEDY_QUICK /* I'm not in love with this implementation. */
  call SLOW_DOWN            /* slow down timer     */
  br END_PUSHBUTTON_ISR     /* return              */
SPEEDY_QUICK:
  call SPEED_UP             /* speed up timer      */
  br END_PUSHBUTTON_ISR     /* return              */

/* Check key 1 -------------------------------------------------------------- */
CHECK_KEY1:
  andi r8, r9, 0b10      /* mask button 1 with edge register */
  beq r8, r0, CHECK_KEY2 /* if not 1, check second button    */
  call SLOW_DOWN
  br END_PUSHBUTTON_ISR

/* Check key 2 -------------------------------------------------------------- */
CHECK_KEY2:
  andi r8, r9, 0b100    /* mask button 2 with edge register */
  beq r8, r0, END_PUSHBUTTON_ISR /* how did you even get here if this */
                                 /* is not the interrupt?             */
  call SPEED_UP

END_PUSHBUTTON_ISR:
/* Restore stack ------------------------------------------------------------ */
  ldw ra, 0(sp)
  ldw r8, 4(sp)
  ldw r9, 8(sp)
  ldw r10, 12(sp)
  addi sp, sp, 20

  ret

/* ========================================================================== */
/*                             SPEEDUP/SLOWDOWN                               */
/* ========================================================================== */
/* I guess I put these here because the C habits die hard? Dunno.             */

/* I can mangle any of the registers used before in this file because they    */
/* were all only used to determine which procedure to call.                   */
/* So there is no need to set up a stack. Rejoice.                            */
SPEED_UP:
  stw r11, 16(sp)     /* only used for addition of large numbers */
  movia r11, 0x2625A0 /* aforementioned large number             */
/* Deal w/ LEDS ------------------------------------------------------------- */
  movia r8, LEDS            /* LED address         */
  ldw r8, 0(r8)             /* load address        */
  ldwio r9, 0(r8)           /* load LED state      */
  andi r10, r9, 0b10000000  /* check if at limit   */
  bne r10, r0, SPEED_UP_END /* if at limit, escape */
  /* else */
  slli r9, r9, 1         /* shift LEDS     */
  stwio r9, 0(r8)        /* push new state */

/* Deal w/ timer ------------------------------------------------------------ */
  movia r8, TIMER          /* timer address   */
  ldw r8, 0(r8)            /* load address    */
  stwio r0, 0(r8)          /* reset <--- this might need to be removed */
  movi r9, 0b1011          /* stop = 1, start = 0, cont = 1, ITO = 1 */
  stwio r9, 4(r8)          /* suspend the timer */
  ldwio r9, 8(r8)       /* load low value  */
  ldwio r10, 12(r8)     /* load high value */
  slli r10, r10, 16     /* shift into upper half */
  or r9, r9, r10        /* combine               */
  sub r9, r9, r11       /* subtract 50ms from the period */
  andi r10, r9, 0xFFFF  /* pull out lower half           */
  srli r9, r9, 16       /* shift upper bits into place   */
  stwio r10, 8(r8)      /* store low bits  */
  stwio r9, 12(r8)      /* store high bits */
  movi r9, 0b111           /* start = 1, cont = 1, ITO = 1 */
  stwio r9, 4(r8)          /* start the timer again        */

SPEED_UP_END:
  ldw r11, 16(sp)  /* This is only needed for the speed change  */
                   /* as 2.5M is way out of the range of 2^15   */
  ret

/* This is just cp+mv of above with sub->add and checking low LED instead     */
SLOW_DOWN:
  stw r11, 16(sp)     /* only used for addition of large numbers */
  movia r11, 0x2625A0 /* aforementioned large number             */
/* Deal w/ LEDS ------------------------------------------------------------- */
  movia r8, LEDS             /* LED address         */
  ldw r8, 0(r8)              /* load address    */
  ldwio r9, 0(r8)            /* load LED state      */
  andi r10, r9, 0b10         /* check if at limit   */
  bne r10, r0, SLOW_DOWN_END /* if at limit, escape */
  /* else */
  srli r9, r9, 1         /* shift LEDS     */
  stwio r9, 0(r8)        /* push new state */

/* Deal w/ timer ------------------------------------------------------------ */
  movia r8, TIMER          /* timer address   */
  ldw r8, 0(r8)            /* load address    */
  stwio r0, 0(r8)          /* reset <--- this might need to be removed */
  movi r9, 0b1011          /* stop = 1, start = 0, cont = 1, ITO = 1 */
  stwio r9, 4(r8)          /* suspend the timer */
  ldwio r9, 8(r8)       /* load low value  */
  ldwio r10, 12(r8)     /* load high value */
  slli r10, r10, 16     /* shift into upper half */
  or r9, r9, r10        /* combine               */
  add r9, r9, r11       /* subtract 50ms from the period */
  andi r10, r9, 0xFFFF  /* pull out lower half           */
  srli r9, r9, 16       /* shift upper bits into place   */
  stwio r10, 8(r8)      /* store low bits  */
  stwio r9, 12(r8)      /* store high bits */
  movi r9, 0b111           /* start = 1, cont = 1, ITO = 1 */
  stwio r9, 4(r8)          /* start the timer again        */

SLOW_DOWN_END:
  ldw r11, 16(sp)  /* This is only needed for the speed change  */
                   /* as 2.5M is way out of the range of 2^15   */
  ret

  .end

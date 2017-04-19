/* -------------------------------------------- */
/* Derek Prince                                 */
/* ECEN 3350: Programming Digital Systems       */
/* Assignment 5 - Scrolling Interrupts          */
/* Interval Timer ISR                           */
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
/* |                 r13                 | 20(sp)                             */
/* ---------------------------------------                                    */
/* |                 r12                 | 16(sp)                             */
/* ---------------------------------------                                    */
/* |                 r11                 | 12(sp)                             */
/* ---------------------------------------                                    */
/* |                 r10                 |  8(sp)                             */
/* ---------------------------------------                                    */
/* |                 r9                  |  4(sp)                             */
/* ---------------------------------------                                    */
/* | sp ->           r8                  |  0(sp)                             */
/* ---------------------------------------                                    */
/* responsible for updating displays */
/* and that's about it.              */

  .global INTERVAL_TIMER_ISR
INTERVAL_TIMER_ISR:
/* Setup stack -------------------------------------------------------------- */
  addi sp, sp, -24  /* >Space Created */
  stw r8, 0(sp)
  stw r9, 4(sp)
  stw r10, 8(sp)
  stw r11, 12(sp)

/* Timer handling ----------------------------------------------------------- */
  movia r8, TIMER   /* timer base address mem location                        */
  ldw r8, 0(r8)     /* load timer base address                                */
  stwio r0, 0(r8)   /* clear interrupt. RUN bit is not writeable regardless   */

/* Display Madness ---------------------------------------------------------- */
/* As an improvement over the last program, I'm going to try to just          */
/* circulate the MESSAGE memory and use the first word as the display state   */
/* The last word has 4 bytes of empty memory though. So avoid that in the mask*/

/* There are a few edge cases (such as doing the first word in two parts      */
/* and the last word being half empty) but the general form is...             */
/* 1. load word                                                               */
/* 2. mask out bits that will otherwise be lost from the shift                */
/* 3. shift word one display length (in bit length - 8)                       */
/* 4. shift the previous words display message (that was pulled from it's     */
/*    respective line 2) into alignment with the new empty bits from shift    */
/* 5. save that shit.                                                         */
/* Note: 0x7F masks everything but the decimal. Which is good.                */

  movia r8, DISPLAY
  ldw r8, 0(r8)      /* load display address      */
  movia r9, MESSAGE
  ldw r9, 0(r9)      /* load message base address */
  /* to preserve the data, I'm going to cycle left and work back to the start */
  /* filling in the first shift last.                                         */

/* 1st word pt.1 */
  ldw r10, 0x0(r9)   /* grab first word */
  andi r12, r10, 0x7F000000  /* mask bits-to-be-shifted (first) */
  slli r10, r10, 8   /* shift one display's bit-length                     */
  stw r10, 0(r9)     /* this is to preserve my sanity for when I come back */

/* 5th (last) word */
  ldw r11, 0x10(r9)  /* grab last word   */
  andi r13, r11, 0x7F000000  /* mask bits-to-be-shifted (last)  */
  slli r11, r11, 8   /* shift one display's bit-length                  */
  srli r12, r12, 8   /* the last word is a special-case word where only */
                     /* the upper half is used                          */
  or r11, r11, r12   /* mask in new bits                                */
  stw r11, 0x10(r9)  /* store that shit before you forget               */

/* 4th word */
  ldw r10, 0xC(r9)   /* grab 4th word */
  andi r12, r10, 0x7F000000 /* mask bits-to-be-shifted (4th) */
  slli r10, r10, 8   /* shift one display's bit-length                  */
  srli r13, r13, 24  /* shift to start of word                          */
  or r10, r10, r13   /* mask in bits from 5th word                      */
  stw r10, 0xC(r6)   /* sanity save                                     */

/* 3rd word */
  ldw r11, 0x8(r9)   /* grab 3rd word   */
  andi r13, r11, 0x7F000000  /* mask bits-to-be-shifted (last)  */
  slli r11, r11, 8   /* shift one display's bit-length                  */
  srli r12, r12, 24  /* shift to start of word                          */
  or r11, r11, r12   /* mask in new bits                                */
  stw r11, 0x8(r9)   /* sanity save                                     */

/* 2nd word */
  ldw r10, 0x4(r9)   /* grab 4th word */
  andi r12, r10, 0x7F000000 /* mask bits-to-be-shifted (4th) */
  slli r10, r10, 8   /* shift one display's bit-length                  */
  srli r13, r13, 24  /* shift to start of word                          */
  or r10, r10, r13   /* mask in bits from 5th word                      */
  stw r10, 0x4(r6)   /* sanity save                                     */

/* 1st word pt.2 */
  ldw r11, 0x0(r9)   /* grab 1st word   */
  srli r12, r12, 24  /* shift to start of word                          */
  or r11, r11, r12   /* mask in new bits                                */
  stw r11, 0x0(r9)   /* sanity save                                     */

  /* And now pray it worked. */

/* Update display ----------------------------------------------------------- */
  stwio r11, 0(r8)

/* Restore stack ------------------------------------------------------------ */
  ldw r8, 0(sp)
  ldw r9, 4(sp)
  ldw r10, 8(sp)
  ldw r11, 12(sp)
  addi sp, sp, 24  /* >Well Played! */
  ret

 .end

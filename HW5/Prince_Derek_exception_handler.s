/* -------------------------------------------- */
/* Derek Prince                                 */
/* ECEN 3350: Programming Digital Systems       */
/* Assignment 4 - Question 2.                   */
/* Scrolling things and reverse patterns        */
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
/* |                 r8                  | 12(sp)                             */
/* ---------------------------------------                                    */
/* |                 ra                  |  8(sp)                             */
/* ---------------------------------------                                    */
/* |                 ea                  |  4(sp)                             */
/* ---------------------------------------                                    */
/* | sp ->           et                  |  0(sp)                             */
/* ---------------------------------------                                    */

/* ========================================================================== */
/*                                   RESET                                    */
/* ========================================================================== */
  .section .reset, "ax"
  movia r2, _start
  jmp r2                 /* reset with impunity */

/* ========================================================================== */
/*                                 EXCEPTIONS                                 */
/* ========================================================================== */
/* Only the pushbuttons and the timer have interrupts enabled.         */
/* Should be able to have a strict priority instead of fancy swapping. */
/* Moreover, I want the timer to be regular.                           */

  .section .exceptions, "ax"
  .global EXCEPTION_HANDLER

EXCEPTION_HANDLER:
/* Set Up Stack ------------------------------------------------------------- */
/* Save anything that is used. 'Caller' saves nothing. */
  addi sp, sp, -16 /* set to whatever is needed              */
  stw et, 0(sp)     /* et is just r24 (exception temporary)   */

  rdctl et, ipending
  beq et, r0, SKIP_EA_DEC /* skips ea decrement if interrupt is not  */
                          /* external.                               */

  subi ea, ea, 4

SKIP_EA_DEC:
  stw ea, 4(sp)   /* store exception return                       */
  stw ra, 8(sp)   /* for calling handlers                         */
  stw r8, 12(sp)  /* arbitrary reg I'm going to use.              */

  bne et, r0, CHECK_LEVEL_0 /* et is still populated from above code */

NOT_EI:
  br END_ISR /* Not external interrupt. Not handled here. */

/* Check timer -------------------------------------------------------------- */
CHECK_LEVEL_0:
  andi r8, et, 0b1             /* mask out level-0 bit into r8       */
  beq r8, r0, CHECK_LEVEL_1    /* If not timer interrupt, check next */

  call INTERVAL_TIMER_ISR      /* Otherwise handle timer             */
  br END_ISR                   /* then return skip to end            */

/* Check pushbuttons -------------------------------------------------------- */
CHECK_LEVEL_1:
  andi r8, et, 0b010           /* mask out level-1 bit into r8           */
  beq r8, r0, END_ISR          /* if not, break to end. Only two enabled */

  call PUSHBUTTON_ISR

END_ISR:
/* Restore stack ------------------------------------------------------------ */
  ldw et, 0(sp)
  ldw ea, 4(sp)
  ldw ra, 8(sp)
  ldw r8, 12(sp)
  addi sp, sp, 16
  eret

  .end

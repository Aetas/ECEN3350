/* --------------------------------------- */
/* Derek Prince                            */
/* ECEN 3350: Programming Digital Systems  */
/* Assignment 2 - Question 2.              */
/* Translate Simple C Code.                */
/* --------------------------------------- */

/*-------------------------------------------------------------------------------*/
/* MIT License                                                                   */
/*                                                                               */
/*Copyright (c) 2017 Derek Prince                                                */
/*                                                                               */
/*Permission is hereby granted, free of charge, to any person obtaining a copy   */
/*of this software and associated documentation files (the "Software"), to deal  */
/*in the Software without restriction, including without limitation the rights   */
/*to use, copy, modify, merge, publish, distribute, sublicense, and/or sell      */
/*copies of the Software, and to permit persons to whom the Software is          */
/*furnished to do so, subject to the following conditions:                       */
/*                                                                               */
/*The above copyright notice and this permission notice shall be included in all */
/*copies or substantial portions of the Software.                                */
/*                                                                               */
/*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR     */
/*IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,       */
/*FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE    */
/*AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER         */
/*LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,  */
/*OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE  */
/*SOFTWARE.                                                                      */
/*-------------------------------------------------------------------------------*/

.global _start

_start:
/* load X, Y, and Z addresses into registers */
	movia r2, X
	movia r3, Y
	movia r4, Z
/* might as well grab the values while I'm at it. */
	ldw r5, 0(r2)				/* x value */
	ldw r6, 0(r3)				/* y value */

/* now for the conditional */
	ble r5, r6, ELSE 		/* if x <= y, do ELSE statement. Otherwise fall through */

	addi r7, r0, 1 			/* r7 = 0 + 1, Z will take r7's value. */
	stw r7, 0(r4)				/* store Z */
	br END							/* skip ELSE case */

ELSE:
	subi r7, r0, 1			/* r7 = 0 - 1, Z will take r7's value */
	stw r7, 0(r4)				/* store Z */

END:
	br END							/* loop fo' eva'. Because why not. */

.data
X:
	.word 13
Y:
	.word 2
Z:
	.word 0

.end

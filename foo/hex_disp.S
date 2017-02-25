/* ------------------------------------------------ */
/* Derek Prince										                  */
/* NIOS II "Hex display numbers"                    */
/* a.k.a. "waiting for network access program #2" 	*/
/* ------------------------------------------------ */

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


.include "nios_macros.s"

.global _start

_start
/* index ------------------------------ */
/* r1 -> DE0 switches address           */
/* r2 -> DE0 HEX display address        */
/* r3 -> HEX coded output address root  */
/* r4 -> switch value (word)byte        */
/* r5 -> relevant HEX value             */
/* r6 -> Specific HEX code address      */

/* grab addresses */
movia r1, 0x10000040	/* Switches DE0 address	*/
movia r2, 0x10000020	/* HEX DISP DE0 address	*/
movia r3, HEX					/* HEX coded outputs. 	*/

/* grab values */
ldw r4, 0(r1)

/* first check if number is greater than 9. */
bgt r4, 0x9, GREATER

/* else shift left twice to get a multiple of 4 that can be used to for byte offset. */
slli r4, r4, 2

add r6, r4, r3 /* get address shifted from root */

/* grab specific HEX value to save in memory 	*/
ldw r5, 0(r6)	  /* grabs HEX value 				    */
stw r5, 0(r2)	  /* stores in HEX address 		  */

br END	/* skip greater case if above code executes */

GREATER:
	/* just the dot is 01000000: 0x40 */
	stw 0x00000040, 0(r2)

END:
	br END

.data
HEX:	/* coded outputs for hex displays */
	.word 0b00011111, 0b00000110, 0b01011011, 0b01001111, 0b00100110,
		  0b01101101, 0b01111100, 0b00000111, 0b01111111, 0b01100111


.end

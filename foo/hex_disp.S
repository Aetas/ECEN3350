/* Derek Prince										*/
/* NIOS II "Hex display numbers" 					*/
/* a.k.a. "waiting for network access program #2" 	*/

.include "nios_macros.s"

.global _start

_start
/* index ------------------------------ */
/* r1 -> DE0 switches address 			*/
/* r2 -> DE0 HEX display address		*/
/* r3 -> HEX coded output address root	*/
/* r4 -> switch value (word)byte		*/
/* r5 -> relevant HEX value				*/

/* grab addresses */
movia r1, 0x10000040	/* Switches DE0 address	*/
movia r2, 0x10000020	/* HEX DISP DE0 address	*/
movia r3, HEX			/* HEX coded outputs. 	*/

/* grab values */
ldw r4, 0(r1)

/* first check if number is greater than 9. */
bgt r4, 0x9, GREATER

/* else shift left twice to get a multiple of 4 that can be used to for byte offset. */
slli r4, 2
/* grab specific HEX value to save in memory 	*/
ldw r5, r4(r3)	/* grabs HEX value 				*/
stw r5, 0(r2)	/* stores in HEX address 		*/

/* can you just...		*/
/* stw r4(r3), 0(r2)	*/
/*			?			*/

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
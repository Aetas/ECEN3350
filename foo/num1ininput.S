/* Derek Prince											*/
/* NIOS II "Count number of 1's in a bin num program" 	*/
/* a.k.a. "waiting for network access program" 			*/

.include "nios_macros.s"

.global _start
/* index -------------------------- */
/* r1 -> input address 				*/
/* r2 -> output address 			*/
/* r3 -> input value 				*/
/* r4 -> counter 					*/
/* r5 -> intermediate sum element 	*/

_start

movia r1, X			/* grab address holding value 	*/
movia r2, Y			/* grab address for sum storage */
ldw r3, 0(r1)		/* grab value from address 		*/

and r4, r4, r0		/* initialize count to 0.	*/

/* 
LOOP:
andi r5, r2, 0x1	/* check for 1 */
add r4, r4, r5		/* add r5 to r4. Will only be 1 if the inputs LSB is a 1 */
sri r3, 1			/* shift for next iteration */
 
bgt r3, r0, LOOP	/* re-run the loop if input is greater than 0 */

stw r4, 0(r2)		/* store the final sum in memory (Y) */

HOLD:	/* loop fo eva. This makes debugging easy. */
	br HOLD



.data
X:		/* input */
	.word 0xfab123
Y:		/* output sum */
	.word 0

.end
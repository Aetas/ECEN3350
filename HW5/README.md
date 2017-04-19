To run this program in the Altera Monitor Program, you must set the .text and
.data sections to have an offset. 400 worked for me.

Additionally, it might be fine without if it is run standalone (I don't know
why it wouldn't be). I set the pattern manually in setup to avoid linking mangle.

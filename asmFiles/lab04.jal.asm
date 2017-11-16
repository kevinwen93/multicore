# Author: Xihui Wang <wang1540@purdue.edu>

main:
	ori $1, $0, 0x12
	ori $2, $0, 0x23
	jal loop
	ori $3, $0, 0x34
	halt

loop:	ori $4, $0, 0x45
	ori $5, $0, 0x56
	jr  $31

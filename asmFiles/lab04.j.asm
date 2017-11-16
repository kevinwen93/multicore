# Simple jump test.
# Author: Subhav Ramachandran <subhav@purdue.edu>

main:
	ori $2, $0, 0x1234
	ori $3, $0, 0x1234
	j jumptarget
	ori $4, $0, 0x1234
	ori $5, $0, 0x1234
	ori $6, $0, 0x1234

jt2:

	sw $7, 200($0)
	sw $8, 204($0)
	sw $9, 208($0)
	sw $10, 212($0)
	halt


jumptarget:
	ori $7, $0, 0x1234
	ori $8, $0, 0x1234
	ori $9, $0, 0x1234
	ori $10, $0, 0x1234
	j jt2

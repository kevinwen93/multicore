
	org  0x0000
	ori  $29, $0, 0xfffc
	ori  $2, $0, 0x0002
	ori  $3, $0, 0x0003
	
	push $2
	push $3

	addi $5, $0, 0        #$4 = 1
	
	pop  $6
	pop  $7
	beq  $7, $0, zero
	
	j    mult
	
mult:	add  $5, $5, $6
	addi $7, $7, -1
	bne  $7, $0, mult
	j    exit

zero:	addi $5, $0, 0
	j    exit

exit:	push $5
	halt

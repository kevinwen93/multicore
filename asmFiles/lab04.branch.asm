# Author: Xihui Wang <wang1540@purdue.edu>

main:
	ori $1, $0, 0x31
	ori $2, $0, 0x31
	ori $3, $0, 0x35

	beq $2, $3, error
	beq $1, $2, corr

end:	halt
	
error:
	ori $5, $0, 0x12
	j   end

corr:
	ori $5, $0, 0x23
	bne $1, $3, corr2
	j   end

corr2:
	ori $5, $0, 0x34
	j   end


  org   0x0200
	halt

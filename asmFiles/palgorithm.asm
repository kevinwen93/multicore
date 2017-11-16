#----------------------------------------------------------
# First Processor
#----------------------------------------------------------
 	org	0x0000              	# first processor p0
	ori	$sp, $zero, 0x3ffc  	# stack pointer
	ori	$s0, $0, 0x0800		# head of stack buffer
	ori	$s1, $0, 0		# current count
	ori	$s2, $0, 256		# max count value 256	
	ori	$s6, $0, 0x0850		# addr of stack buffer ind
	ori	$s7, $0, 1		# seed
	
	jal	mainp0              # go to program
	halt
#----------------------------------------------------------
# lock
#----------------------------------------------------------
# pass in an address to lock function in argument register 0
# returns when lock is available
lock:
aquire:
	ll	$t0, 0($a0)         # load lock location
	bne	$t0, $0, aquire     # wait on lock to be open
	addiu	$t0, $t0, 1
	sc	$t0, 0($a0)
	beq	$t0, $0, lock       # if sc failed retry
	jr	$ra


# pass in an address to unlock function in argument register 0
# returns when lock is free
unlock:
	sw	$0, 0($a0)
	jr	$ra
	
# main function does something ugly but demonstrates beautifully
mainp0:
	beq	$s1, $s2, finishp0
	jal	produce
	j	mainp0
	
produce:
	lw	$s5, 0($s6)		# stack ind
	beq	$s5, 0x0824, produce
	
	push	$ra	# save return address	
	ori	$a0, $0, lock_val
	jal	lock

	# generate random vals
	
	or	$a0, $0, $s7
	jal	crc32	#call crc32
	sw	$v0, 0($s5)
	or	$s7, $0, $v0

	# update index, count, addr
	addi	$s1, $s1, 1
	addi	$s5, $s5, 4
	sw	$s5, 0($s6)

	ori	$a0, $0, lock_val
	jal	unlock
	pop $ra	
	jr  $ra
	
finishp0:
	#lw	$t0, 36($s0)
	#lw	$t1, 4($s0)
	lw	$t2, 0($s6)
	halt  

#----------------------------------------------------------
# Second Processor
#----------------------------------------------------------
	org	0x200               	# second processor p1
	ori	$sp, $zero, 0x7ffc  	# stack pointer
	ori	$s0, $0, 0x0824		# head of stack buffer
	ori	$s1, $0, 0		# current count
	ori	$s2, $0, 256		# max count value 256
	ori	$s6, $0, 0x0850		# addr of stack buffer ind
	ori	$s7, $0, 0x0900		# results

	lw	$t0, 0($s6)
	jal   mainp1              # go to program
	halt

# main function does something ugly but demonstrates beautifully
mainp1:
	beq	$s1, $s2, finishp1
	jal	consume
	j	mainp1

consume:
	lw	$s5, 0($s6)	# current addr, the top of stack
	beq	$s5, 0x800, consume
	
	push	$ra	# save return address
	
	ori	$a0, $0, lock_val
	jal	lock

	# find the max, min, sum
	lw	$t3, 0($s5)	# current value

	lw	$t0, 0($s7)	# max
	lw	$t1, 4($s7)	# min
	lw	$t2, 8($s7)	# sum

	# find max
	or	$a0, $0, $t0
	or	$a1, $0, $t3
	jal 	max
	or	$t0, $0, $v0
	sw	$t0, 0($s7)

	# find min
	or	$a0, $0, $t1
	or	$a1, $0, $t3
	jal 	min
	or	$t1, $0, $v0
	sw	$t1, 4($s7)
	
	# update max, min, sum, count, addr
	addi	$s1, $s1, 1
	addi	$s5, $s5, -4
	add	$t2, $t2, $t3
	sw	$t2, 8($s7)
	sw	$s5, 0($s6)
	ori	$a0, $0, lock_val
	jal	unlock
	pop $ra
	jr  $ra

finishp1:
	lw	$t4, 0($s6)
	halt

	
#----------------------------------------------------------
# init buffer
#----------------------------------------------------------
	org	0x0800
buffer:
	cfw	0x0000	#800
	cfw	0x0000	#804
	cfw	0x0000	#808
	cfw	0x0000  #80c
	cfw	0x0000	#810
	cfw	0x0000	#814
	cfw	0x0000	#818
	cfw	0x0000	#81C
	cfw	0x0000	#820
	cfw	0x0000	#824

	org	0x0850
location:
	cfw	0x0800
	
#----------------------------------------------------------
# init results
#----------------------------------------------------------
	org	0x900
max_val:
	cfw	0x0000
min_val:
	cfw	0x0000
sum_val:
	cfw	0x0000
	
#----------------------------------------------------------
# init lock value
#----------------------------------------------------------
lock_val:
	cfw 0x0000

	
#REGISTERS
#at $1 at
#v $2-3 function returns
#a $4-7 function args
#t $8-15 temps
#s $16-23 saved temps (callee preserved)
#t $24-25 temps
#k $26-27 kernel
#gp $28 gp (callee preserved)
#sp $29 sp (callee preserved)
#fp $30 fp (callee preserved)
#ra $31 return address

# USAGE random0 = crc(seed), random1 = crc(random0)
#       randomN = crc(randomN-1)
#------------------------------------------------------
# $v0 = crc32($a0)
crc32:
  lui $t1, 0x04C1
  ori $t1, $t1, 0x1DB7
  or $t2, $0, $0
  ori $t3, $0, 32

l1:
  slt $t4, $t2, $t3
  beq $t4, $zero, l2

  srl $t4, $a0, 31
  sll $a0, $a0, 1
  beq $t4, $0, l3
  xor $a0, $a0, $t1
l3:
  addiu $t2, $t2, 1
  j l1
l2:
  or $v0, $a0, $0
  jr $ra
#------------------------------------------------------




	
# registers a0-1,v0-1,t0
# a0 = Numerator
# a1 = Denominator
# v0 = Quotient
# v1 = Remainder

#-divide(N=$a0,D=$a1) returns (Q=$v0,R=$v1)--------
divide:               # setup frame
  push  $ra           # saved return address
  push  $a0           # saved register
  push  $a1           # saved register
  or    $v0, $0, $0   # Quotient v0=0
  or    $v1, $0, $a0  # Remainder t2=N=a0
  beq   $0, $a1, divrtn # test zero D
  slt   $t0, $a1, $0  # test neg D
  bne   $t0, $0, divdneg
  slt   $t0, $a0, $0  # test neg N
  bne   $t0, $0, divnneg
divloop:
  slt   $t0, $v1, $a1 # while R >= D
  bne   $t0, $0, divrtn
  addiu $v0, $v0, 1   # Q = Q + 1
  subu  $v1, $v1, $a1 # R = R - D
  j     divloop
divnneg:
  subu  $a0, $0, $a0  # negate N
  jal   divide        # call divide
  subu  $v0, $0, $v0  # negate Q
  beq   $v1, $0, divrtn
  addiu $v0, $v0, -1  # return -Q-1
  j     divrtn
divdneg:
  subu  $a0, $0, $a1  # negate D
  jal   divide        # call divide
  subu  $v0, $0, $v0  # negate Q
divrtn:
  pop $a1
  pop $a0
  pop $ra
  jr  $ra
#-divide--------------------------------------------




	
# registers a0-1,v0,t0
# a0 = a
# a1 = b
# v0 = result

#-max (a0=a,a1=b) returns v0=max(a,b)--------------
max:
  push  $ra
  push  $a0
  push  $a1
  or    $v0, $0, $a0
  slt   $t0, $a0, $a1
  beq   $t0, $0, maxrtn
  or    $v0, $0, $a1
maxrtn:
  pop   $a1
  pop   $a0
  pop   $ra
  jr    $ra
#--------------------------------------------------

#-min (a0=a,a1=b) returns v0=min(a,b)--------------
min:
  push  $ra
  push  $a0
  push  $a1
  or    $v0, $0, $a0
  slt   $t0, $a1, $a0
  beq   $t0, $0, minrtn
  or    $v0, $0, $a1
minrtn:
  pop   $a1
  pop   $a0
  pop   $ra
  jr    $ra
#--------------------------------------------------

# Author: Gregg Weaver <gweaver@purdue.edu>

org 0x0000
  ori   $1,$zero,0xD269
  ori   $2,$zero,0x37F1

  ori   $21,$zero,0x80
  ori   $22,$zero,0xF0

# Now running all-ish I type instructions
  addiu    $3,$1,0x37F1
  andi   $4,$1,0x37F1
  andi  $5,$1,0xF
  lui  $6, 0x37F1
  ori $7,$3,0x8740
  slti  $8,$4,0x37F1
  sltiu   $9,$5,0x37F1
  xori  $10,$1,0xf33f
# Store them to verify the results
  sw    $3,0($21)
  sw    $4,4($21)
  sw    $5,8($21)
  sw    $6,12($21)
  sw    $7,16($21)
  sw    $8,20($21)
  sw    $9,24($21)
  sw    $10,28($21)
  halt  # that's all

  org   0x0200
	halt

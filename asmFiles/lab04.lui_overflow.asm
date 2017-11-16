# Author: Gregg Weaver <gweaver@purdue.edu>

  org 0x0000
  lui $1, 0x7FFF
  ori $2, $0, 0xFFFF
  add $1, $1, $2
  ori $2, $0, 1
  addu $3, $1, $2
  add $4, $1, $2
  sw $4, 48($0)
  halt

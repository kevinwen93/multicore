# Author: Gregg Weaver <gweaver@purdue.edu>

  org 0x0000
  ori $1, $0, 2
  ori $2, $0, 0x0010
  jr $2

  org 0x000C
  ori $1, $0, 3
  sw $1, 28($0)
  halt

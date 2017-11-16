`include "control_unit_if.vh"
`include "cpu_types_pkg.vh"
`timescale 1 ns / 1 ns
parameter PERIOD = 10;
import cpu_types_pkg::*;
module control_unit_tb;
   control_unit_if cuif();
   control_unit CU(cuif);
   logic CLK = 0;
   always #(PERIOD/2) CLK++;
   initial begin
      cuif.opcode = RTYPE;
      cuif.funct = SLL;
      #(PERIOD * 1)
      cuif.funct = SLT;
      #(PERIOD * 1)
      cuif.funct = XOR;
      #(PERIOD * 1)
      cuif.opcode = BEQ;
      #(PERIOD * 1)
      cuif.opcode = LUI;
      #(PERIOD * 1)
      cuif.opcode = SW;
   end // initial begin
endmodule

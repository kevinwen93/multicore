`include "cpu_types_pkg.vh"
`timescale 1 ns / 1 ns
parameter PERIOD = 10;
import cpu_types_pkg::*;
module request_unit_tb;
   logic CLK = 0;
   logic nRST, ihit, dhit, MemWrite, dmemREN, dmemWEN, imemREN;
   logic [1:0] MemtoReg;
   request_unit RU(CLK, nRST, ihit, dhit, MemtoReg,MemWrite, dmemREN, dmemWEN, imemREN);
   always #(PERIOD/2) CLK++;
   initial begin
      nRST = 0;
      #(PERIOD * 1)
      nRST = 1;
      #(PERIOD * 1)
      MemtoReg = 2'b01;
      ihit = 1;
      #(PERIOD * 1)
      ihit = 0;
      #(PERIOD * 1)
   end
endmodule

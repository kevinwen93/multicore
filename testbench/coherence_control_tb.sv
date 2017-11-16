`include "cpu_types_pkg.vh"
`include "cache_control_if.vh"

`timescale 1 ns / 1 ns
parameter PERIOD = 10;

import cpu_types_pkg::*;

module coherence_control_tb;
   logic CLK = 0;
   logic nRST;
   always #(PERIOD/2) CLK++;
   
   cache_control_if ccif();
   memory_control CC(CLK, nRST, ccif);

   initial begin
      nRST = 0;
      ccif.cctrans = '1;
      ccif.dWEN = '0;
      ccif.dREN = '0;
      ccif.ramstate = BUSY;
      #(PERIOD)
      nRST = 1;
      ccif.dREN = 2'b01;
      ccif.daddr = {0, 32'hABCD};
      #(PERIOD * 3)
      ccif.cctrans = 2'b01;
      #(PERIOD * 3)
      ccif.ramstate = ACCESS;
      #(PERIOD * 3)
      $finish;
   end
endmodule

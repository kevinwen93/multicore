`include "coherence_control_if.vh"
`include "cpu_types_pkg.vh"
`include "cache_control_if.vh"

`timescale 1 ns / 1 ns
parameter PERIOD = 10;

import cpu_types_pkg::*;

module memory_control_tb;
   logic CLK = 0;
   logic nRST;
   always #(PERIOD/2) CLK++;
   
   coherence_control_if bus_if();
   coherence_control CC(nRST, CLK, bus_if);

   initial begin
      nRST = 0;
      bus_if.cctrans = '1;
      bus_if.cache_dWEN = '0;
      bus_if.cache_dREN = '0;
      bus_if.dwait = 1;
      #(PERIOD)
      nRST = 1;
      bus_if.cache_dREN = 2'b01;
      bus_if.dcache_addr = {0, 32'hABCD};
      #(PERIOD * 3)
      bus_if.cctrans = 2'b01;
      #(PERIOD * 3)
      bus_if.rdwait = 0;
      #(PERIOD * 3)
      $finish;
   end
endmodule

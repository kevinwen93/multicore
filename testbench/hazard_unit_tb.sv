`include "hazard_unit_if.vh"
`include "cpu_types_pkg.vh"
import cpu_types_pkg::*;

`timescale 1 ns / 1 ns

module hazard_unit_tb;
   regbits_t idex_rs;
   regbits_t idex_rt;   
   logic MemRead;   
   regbits_t ifid_rs;   
   regbits_t ifid_rt;
   logic exmem_RegWEN;   
   regbits_t exmem_RegDst;   
   logic mem_RegWEN;   
   regbits_t mem_RegDst;
   logic idex_MemWrite;
   regbits_t stall_rt;
   
   hazard_unit_if huif ();
   hazard_unit HU (.idex_rs(idex_rs),
		   .idex_rt(idex_rt),
		   .MemRead(MemRead),
		   .ifid_rs(ifid_rs),
		   .ifid_rt(ifid_rt),
		   .exmem_RegWEN(exmem_RegWEN),
		   .exmem_RegDst(exmem_RegDst),
		   .mem_RegWEN(mem_RegWEN),
		   .mem_RegDst(mem_RegDst),
		   .idex_MemWrite(idex_MemWrite),
		   .stall_rt(stall_rt),
		   .huif(huif));
   parameter PERIOD = 10;
   logic CLK = 0, nRST;
  
   // clock
   always #(PERIOD/2) CLK++;   
   initial begin
      idex_rs = 0;
      idex_rt = 0;   
      MemRead = 0;   
      ifid_rs = 0;   
      ifid_rt = 0;
      exmem_RegWEN = 0;   
      exmem_RegDst = 0;   
      mem_RegWEN = 0;   
      mem_RegDst = 0;
      idex_MemWrite = 0;
      stall_rt = 0;
      #(PERIOD)
      mem_RegWEN = 1;
      mem_RegDst = 1;
      idex_rs = 1;
      idex_rt = 1;
      #(PERIOD)
      exmem_RegWEN = 1;
      exmem_RegDst = 1;
      #(PERIOD)
      idex_MemWrite = 1;
      #(PERIOD)
      MemRead = 1;
      stall_rt = 1;
      ifid_rs = 1;
      #(PERIOD * 10)
      $finish;
   end
endmodule


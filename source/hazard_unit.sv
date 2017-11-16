`include "cpu_types_pkg.vh"
`include "hazard_unit_if.vh"
import cpu_types_pkg::*;
module hazard_unit(
		   input regbits_t idex_rs,
		   input regbits_t idex_rt,
		   input logic MemRead,
		   input logic MemWrite,
		   input regbits_t ifid_rs,
		   input regbits_t ifid_rt,
		   input logic exmem_RegWEN,
		   input regbits_t exmem_RegDst,
		   input logic mem_RegWEN,
		   input regbits_t mem_RegDst,
		   input logic idex_MemWrite,
		   input regbits_t stall_rt,
		   input datomic,
		   hazard_unit_if.hu huif
		   );
   always_comb begin
      huif.forwarda_src = 2'b00;
      huif.forwardb_src = 2'b00;
      huif.stall = 0;
      huif.memadd_forward = 0;

      if ((MemRead | (MemWrite & datomic)) & ((stall_rt == ifid_rs) | (stall_rt == ifid_rt)) & (stall_rt != 0)) begin
	 huif.stall = 1;
      end

      if (mem_RegWEN & (mem_RegDst != 0) & 
	  !(exmem_RegWEN & (exmem_RegDst != 0) & 
	    (exmem_RegDst == idex_rs)) & (mem_RegDst == idex_rs)) begin
	 huif.forwarda_src = 2'b10;
      end else if (exmem_RegWEN & (exmem_RegDst != 0) & (exmem_RegDst == idex_rs))begin
	 huif.forwarda_src = 2'b01;
      end

      if (mem_RegWEN & (mem_RegDst != 0) & 
	  !(exmem_RegWEN & (exmem_RegDst != 0) & 
	    (exmem_RegDst == idex_rt)) & (mem_RegDst == idex_rt)) begin
	 if(!idex_MemWrite) begin
	    huif.forwardb_src = 2'b10;
	 end else begin
	    huif.memadd_forward = 2'b10;
	 end
      end else if (exmem_RegWEN & (exmem_RegDst != 0) & (exmem_RegDst == idex_rt))begin
	 if(!idex_MemWrite) begin
	    huif.forwardb_src = 2'b01;
	 end else begin
	    huif.memadd_forward = 2'b01;
	 end
      end
   end
endmodule // hazard_unit

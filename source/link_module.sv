`include "cpu_types_pkg.vh"
`include "link_module_if.vh"
`include "cache_pkg.vh"
import cache_pkg::*;
import cpu_types_pkg::*;

module link_module(
		   input CLK,
		   input nRST,
		   link_module_if.lm lmif
		   );
   word_t addr;
   word_t next_addr;
   word_t valid;
   word_t next_valid;

   assign lmif.write_valid = (lmif.addr_cpu == addr) & valid;
   
   always_ff@(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 addr <= 0;
	 valid <= 0;
      end else begin
	 addr <= next_addr;
	 valid <= next_valid;
      end
   end

   always_comb begin
      next_addr = addr;
      next_valid = valid;

      if (lmif.invalid_bus & (lmif.addr_bus == addr)) begin
	 next_valid = 0;
      end else if (lmif.invalid_cpu & (lmif.addr_cpu == addr)) begin
	 next_valid = 0;
      end else if (lmif.update) begin
	 next_valid = 1;
	 next_addr =  lmif.addr_cpu;
      end
   end
endmodule      

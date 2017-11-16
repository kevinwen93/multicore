/*
 Eric Villasenor
 evillase@gmail.com
 
 this block is the coherence protocol
 and artibtration for ram
 */

// interface include
`include "cache_control_if.vh"

// memory types
`include "cpu_types_pkg.vh"

module memory_control (
		       input CLK, nRST,
		       output logic fifo_empty,
		       cache_control_if ccif
		       );
   // type import
   import cpu_types_pkg::*;

   coherence_control_if bus_if();
   coherence_control COC(nRST, CLK, fifo_empty, bus_if);
   
   // number of cpus for cc
   parameter CPUS = 2;
   logic 		     dWEN, dREN, iREN, iwait;
   word_t                    daddr, iaddr;

   assign bus_if.dcache_addr = ccif.daddr;
   assign bus_if.dcache_data = ccif.dstore;
   assign bus_if.cctrans = ccif.cctrans;
   assign bus_if.ccwrite = ccif.ccwrite;
   assign bus_if.cache_dWEN = ccif.dWEN;
   assign bus_if.cache_dREN = ccif.dREN;
   assign bus_if.dload = ccif.ramload;
   assign dWEN = bus_if.dWEN;
   assign dREN = bus_if.dREN;
   assign daddr = bus_if.daddr;
   assign ccif.iload = {ccif.ramload, ccif.ramload};
   assign ccif.dload = bus_if.cache_dload;
   assign ccif.dwait = bus_if.cache_dwait;
   assign ccif.ramstore = bus_if.dstore;
   assign ccif.ramaddr =  (dWEN | dREN)? daddr : iREN? iaddr : 'z;
   assign ccif.ramREN = ((dREN | iREN) & !dWEN)? 1'b1 : 1'b0;
   assign ccif.ramWEN = dWEN? 1'b1 : 1'b0;
   assign ccif.ccwait = bus_if.ccwait;
   assign ccif.ccinv = bus_if.ccinv;
   assign ccif.ccsnoopaddr = bus_if.snoopy_addr;

   //ICache coherence
   always @ * begin
      iREN = 0;
      iaddr = 0;
      ccif.iwait = '1;   
      if (ccif.iREN[0]) begin
	 iREN = 1;
	 ccif.iwait[0] = iwait;
	 iaddr = ccif.iaddr[0];
      end else begin
	 iREN = ccif.iREN[1];
	 ccif.iwait[1] = iwait;
	 iaddr = ccif.iaddr[1];
      end // else: !ifccif.iREN[0]
   end
      
   always @ * begin
      bus_if.dwait = 1'b1;
      iwait = 1'b1;
      
      casez(ccif.ramstate)
	ACCESS: begin
	   bus_if.dwait = !(bus_if.dREN | bus_if.dWEN);
	   iwait = bus_if.dREN | bus_if.dWEN;
	end
	BUSY: begin
	end
	FREE: begin
	   bus_if.dwait = 1'b0;
	   iwait = 1'b0;
	end
	ERROR: begin
	end
      endcase	
   end
   	
endmodule

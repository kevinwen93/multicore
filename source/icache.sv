`include "datapath_cache_if.vh"
`include "cache_control_if.vh"
`include "cache_pkg.vh"

module icache(input logic CLK,
	      input logic nRST,
	      datapath_cache_if.icache dcif,
	      cache_control_if ccif
	      );
   import cache_pkg::*;
   import cpu_types_pkg::*;

   parameter BAD = 32'hBAD1BAD1;
   parameter CPUID = 0;
   
   icache_block_t [15:0]icache;

   istate_t state, nextstate;
   icachef_t imemaddr;

   logic 		  hit;

   assign hit = icache[imemaddr.idx].valid & (icache[imemaddr.idx].tag == imemaddr.tag);

   
   assign ccif.iaddr[CPUID] = dcif.imemaddr;
   assign imemaddr = icachef_t'(dcif.imemaddr);
   
   
   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 icache <= '{default:'0};
	 state <= IDLE;
      end else if (ccif.iREN[CPUID] & ~ccif.iwait[CPUID]) begin
	 state <= nextstate;
	 icache[imemaddr.idx].data <= ccif.iload[CPUID];
	 icache[imemaddr.idx].tag <= imemaddr.tag;
	 icache[imemaddr.idx].valid <= 1;
      end else begin
	 icache <= icache;
	 state <= nextstate;
      end
   end // always_ff @ (posedge CLK, negedge nRST)

   always @ * begin //Next State logic
      ccif.iREN[CPUID] = 0;
      dcif.ihit = 0;
      dcif.imemload = ccif.iload[CPUID];
      nextstate = IDLE;
      
      case(state)
	IDLE: begin
	   if(hit) begin //ihit
	      dcif.ihit = 1;
	      dcif.imemload = icache[imemaddr.idx].data;
	   end else begin // miss
	      nextstate = LOAD;
	   end
	end
	LOAD : begin
	   ccif.iREN[CPUID] = 1;
	   dcif.ihit = ~ccif.iwait[CPUID];
	   if (ccif.iwait[CPUID]) begin
	      nextstate = LOAD;
	   end
	end
	endcase // case (state)
   end
endmodule
   

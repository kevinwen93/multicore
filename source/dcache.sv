`include "datapath_cache_if.vh"
`include "cache_control_if.vh"
`include "cache_pkg.vh"

module dcache(input logic CLK,
	      input logic nRST,
	      input logic buffer_empty,
	      datapath_cache_if.dcache dcif,
	      cache_control_if ccif
	      );
   
   import cache_pkg::*;
   import cpu_types_pkg::*;

   parameter CPUID = 0;
   parameter BAD = 32'hBAD1BAD1;

   dstate_t laststate, state, nextstate, returnstate;
   dcachef_t dmemaddr, last_dmemaddr, snoopaddr;
   
   link_module_if lmif();
   link_module LM(CLK, nRST, lmif);
   assign lmif.addr_cpu = dcif.dmemaddr;
   assign lmif.addr_bus = ccif.ccsnoopaddr;
   logic 		  atomic_faild;
   
   logic 		  address_lock;

   logic 		  snoopy_set, next_snoopy_set; 		  

   logic 		  go_snoopy;		  
   
   word_t last_address;
   logic 		  last_replace_block;
   
   flush_cnt_t flush_cnt;
   logic 		  flush_cnt_en;
   
   assign dmemaddr = dcachef_t'(dcif.dmemaddr);
   assign last_dmemaddr = dcachef_t'(last_address);
   assign snoopaddr = dcachef_t'(ccif.ccsnoopaddr[CPUID]);
   
   twoway_dcache_t [7:0]dcache;
   twoway_dcache_t [7:0]dcache_next;

   logic 		  datomic_reply;

   word_t[1:0]  WB_buffer_data, WB_buffer_addr;
   word_t [1:0] 		  WB_addr, WB_data;
   logic 		  WB;
   
   logic 		  write_done;
   logic 		  hit0, hit1, replace_block;
   logic [1:0] 		  dirty, valid;
   logic 		  latch;
   logic 		  empty;
   logic 		  inv;
   logic 		  write_pass;
   
   
   assign inv = dcache_next[dmemaddr.idx].block[hit1 & !hit0].MESI == INVALID;
   
   assign replace_block = ~valid[0]? 0 : ~valid[1]? 1: ~dcache[dmemaddr.idx].recent;
   assign WB_addr = {{dcache[dmemaddr.idx].block[replace_block].tag, dmemaddr.idx,
		      1'b1, dmemaddr.bytoff},{dcache[dmemaddr.idx].block[replace_block].tag, dmemaddr.idx, 
					      1'b0, dmemaddr.bytoff}};
   assign WB_data = dcache[dmemaddr.idx].block[replace_block].data;
   assign dirty = {(dcache[dmemaddr.idx].block[1].MESI == MODIFIED), (dcache[dmemaddr.idx].block[0].MESI == MODIFIED)};
   assign valid = {(dcache[dmemaddr.idx].block[1].MESI != INVALID), (dcache[dmemaddr.idx].block[0].MESI != INVALID)};
   assign hit0 = (dcache[dmemaddr.idx].block[0].tag == dmemaddr.tag) & valid[0];
   assign hit1 = (dcache[dmemaddr.idx].block[1].tag == dmemaddr.tag) & valid[1];

   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 snoopy_set <= 0;
      end else begin
	 snoopy_set = next_snoopy_set;
      end
   end
  
   always_ff @(posedge CLK, negedge nRST) begin // Write back buffer
      if (!nRST) begin
	 WB_buffer_data <= '{default:'0};
	 WB_buffer_addr <= '{default:'0};
	 WB <= 0;
      end else if (latch) begin
	 WB_buffer_data <= WB_data;
	 WB_buffer_addr <= WB_addr;
	 WB <= 1;
      end else if (empty)begin
	 WB_buffer_data <= '{default:'0};
	 WB_buffer_addr <= '{default:'0};
	 WB <= 0;
      end else begin
	 WB_buffer_data <= WB_buffer_data;
	 WB_buffer_addr <= WB_buffer_addr;
	 WB <= WB;
      end
   end

   always_ff @(posedge CLK, negedge nRST) begin //Load FF
      if (!nRST) begin
	 last_replace_block <= 0;
	 last_address <= 0;
      end else if (address_lock)begin
	 last_address <= last_address;
	 last_replace_block <= last_replace_block;
      end else begin
	 last_address <= dcif.dmemaddr;
	 last_replace_block <= replace_block;
      end
   end
   
   always_ff @(posedge CLK, negedge nRST) begin // Flush counter FF
      if (!nRST) begin
   	 flush_cnt <= 0;
      end else if (flush_cnt_en) begin
   	 flush_cnt <= flush_cnt + 1;
      end else begin
   	 flush_cnt <= flush_cnt;
      end
   end
   
   always_ff @(posedge CLK, negedge nRST) begin //Next state and data FF
      if (!nRST) begin
	 dcache <= '{default:'0};
	 state <= IDLE1;
	 laststate <= IDLE1;
      end else begin
	 dcache <= dcache_next;
	 laststate <= state;
	 state <= nextstate;
      end
   end

   always_ff @ (posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 returnstate = IDLE1;
      end else if (go_snoopy) begin
	 returnstate = state;
      end else begin
	 returnstate = returnstate;
      end
   end
   
   always @ * begin //Output controller
      dcif.dmemload = BAD;
      dcif.dhit = 0;
      
      if (hit0 & dcif.dmemREN & ~ccif.ccwait[CPUID]) begin
   	 dcif.dmemload = dcache[dmemaddr.idx].block[0].data[dmemaddr.blkoff];
   	 dcif.dhit = 1;
      end else if (hit1 & dcif.dmemREN & ~ccif.ccwait[CPUID]) begin
   	 dcif.dmemload = dcache[dmemaddr.idx].block[1].data[dmemaddr.blkoff];
   	 dcif.dhit = 1;
      end else if (dcif.dmemWEN & ~ccif.ccwait[CPUID]) begin
   	 dcif.dhit = write_done;
   	 dcif.dmemload = datomic_reply;
      end else if ((state == LOAD2) & dcif.dmemREN & (laststate == LOAD1) & ~ccif.ccwait[CPUID]) begin
   	 dcif.dhit = 1;
   	 dcif.dmemload = dcache[last_dmemaddr.idx].block[last_replace_block].data[last_dmemaddr.blkoff];
      end
   end // always_comb begin

   always @ * begin //Next State Logic
      nextstate = state;
      dcache_next = dcache;
      ccif.dWEN[CPUID] = 0;
      ccif.dREN[CPUID] = 0;
      ccif.dstore[CPUID] = 0;
      ccif.daddr[CPUID] = dcif.dmemaddr;
      ccif.ccwrite[CPUID] = 0;
      ccif.cctrans[CPUID] = 1;
      dcif.flushed = 0;
      flush_cnt_en = 0;
      address_lock = 0;
      write_done = 0;
      latch = 0;
      empty = 0;
      next_snoopy_set = snoopy_set;
      lmif.update = dcif.datomic & dcif.dmemREN;
      lmif.invalid_cpu = 0;
      lmif.invalid_bus = 0;
      go_snoopy = 0;
      atomic_faild = 0;
      datomic_reply = 0;
      
      case(state)
	IDLE1: begin
	   if (ccif.ccwait[CPUID]) begin
	      nextstate = SNOOPY;
	      go_snoopy = 1;
	   end else if (dcif.halt) begin //Flush the cache to Memory
	      nextstate = FLUSH; 
	   end else if (dcif.dmemREN | dcif.dmemWEN) begin
	      if (hit0) begin //block0 hit
		 dcache_next[dmemaddr.idx].recent = 0;
		 if (dcif.dmemWEN) begin
		    nextstate = WRITE;
		    ccif.ccwrite[CPUID] = ~dcif.datomic;
		 end
	      end else if (hit1) begin //block1 hit
		 dcache_next[dmemaddr.idx].recent = 1;
		 if (dcif.dmemWEN) begin
		    nextstate = WRITE;
		    ccif.ccwrite[CPUID] = ~dcif.datomic;
		 end
	      end else begin//Miss
		 if (dirty[replace_block] & valid[replace_block]) begin //Find out if not LRU block is dirty
		    latch = 1;
		 end
		 nextstate = LOAD1;
	      end // else: !if(hit1)
	   end // if (dcif.dmemREN | dcif.dmemWEN)
	end // case: IDEL
	
	LOAD1: begin
	   if (ccif.ccwait[CPUID]) begin
	      nextstate = SNOOPY;
	      go_snoopy = 1;
	   end else if (!ccif.dwait[CPUID]) begin
	      nextstate = LOAD2;
	   end
	   lmif.update = dcif.datomic;
	   dcache_next[dmemaddr.idx].block[replace_block].data[dmemaddr.blkoff] = ccif.dload[CPUID];
	   dcache_next[dmemaddr.idx].block[replace_block].MESI = INVALID;
	   address_lock = 1;
	   ccif.dREN[CPUID] = 1;
	   ccif.dWEN[CPUID] = WB;
	end

	LOAD2: begin
	   if (!ccif.dwait[CPUID]) begin
	      dcache_next[last_dmemaddr.idx].block[last_replace_block].MESI = SHARED;
	      dcache_next[last_dmemaddr.idx].block[last_replace_block].tag = last_dmemaddr.tag;
	      dcache_next[last_dmemaddr.idx].recent = last_replace_block;
	      ccif.cctrans[CPUID] = 0;
	      if (!WB) begin
		 nextstate = IDLE1;
	      end else begin
		 nextstate = WRITE_BACK1;
	      end
	   end // if (!ccif.dwait)
	   dcache_next[last_dmemaddr.idx].block[last_replace_block].data[~last_dmemaddr.blkoff] = ccif.dload[CPUID];
	   address_lock = 1;
	   ccif.daddr[CPUID] = {last_dmemaddr.tag, last_dmemaddr.idx, ~last_dmemaddr.blkoff, last_dmemaddr.bytoff};
	   ccif.dREN[CPUID] = 1;
	   ccif.dWEN[CPUID] = WB;
	end

	WRITE: begin
	   if (ccif.ccwait[CPUID]) begin
	      nextstate = SNOOPY;
	      go_snoopy = 1;
	   end else if (~(~dcif.datomic | lmif.write_valid) | ~ccif.dwait[CPUID] | inv) begin
	      nextstate = IDLE1;
	   end
	   if ((~dcif.datomic | lmif.write_valid) & ~ccif.ccwait[CPUID] & ~inv) begin
	      datomic_reply = 1;
	      ccif.ccwrite[CPUID] = 1;
	      dcache_next[dmemaddr.idx].block[hit1 & !hit0].MESI = MODIFIED;
	      dcache_next[dmemaddr.idx].block[hit1 & !hit0].data[dmemaddr.blkoff] = dcif.dmemstore;
	      lmif.invalid_cpu = ~ccif.dwait[CPUID];
	   end else if (~ccif.ccwait[CPUID]) begin
	      datomic_reply = 0;
	      atomic_faild = dcif.datomic;
	   end
	   write_done = (~ccif.dwait[CPUID] & ~ccif.ccwait[CPUID]) | atomic_faild;
	end
	
	WRITE_BACK1: begin // Write lower word into memory
	   if (!ccif.dwait[CPUID]) begin
	      nextstate = WRITE_BACK2;
	   end
	   ccif.dWEN[CPUID] = 1;
	   ccif.dstore[CPUID] = WB_buffer_data[0];
	   ccif.daddr[CPUID] = WB_buffer_addr[0];
	end
	
	WRITE_BACK2: begin // Write higher word into memory
	   if (!ccif.dwait[CPUID]) begin
	      empty = 1;
	      nextstate = IDLE1;
	      ccif.cctrans[CPUID] = 0;
	   end
	   ccif.dWEN[CPUID] = 1;
	   ccif.dstore[CPUID] = WB_buffer_data[1];
	   ccif.daddr[CPUID] = WB_buffer_addr[1];
	end
	
	FLUSH: begin //Flush the cache back to memory
	   if (ccif.ccwait[CPUID]) begin
	      nextstate = SNOOPY;
	      go_snoopy = 1;
	   end else if (dcache[flush_cnt.index].block[flush_cnt.set].MESI == MODIFIED) begin
	      if (!ccif.dwait[CPUID]) begin
		 if (flush_cnt.word_sel == 1) begin
		    dcache_next[flush_cnt.index].block[flush_cnt.set].MESI = INVALID;
		 end
		 nextstate = FLUSH_NEXT;
	      end
	      ccif.cctrans[CPUID] = 1;
	      ccif.dWEN[CPUID] = 1;
	      ccif.dstore[CPUID] = dcache[flush_cnt.index].block[flush_cnt.set].data[flush_cnt.word_sel];
	      ccif.daddr[CPUID] = {dcache[flush_cnt.index].block[flush_cnt.set].tag,
			    flush_cnt.index,flush_cnt.word_sel, 2'b00};
	   end else begin
	      if (flush_cnt.word_sel == 1) begin
		 dcache_next[flush_cnt.index].block[flush_cnt.set].MESI = INVALID;
	      end
	      nextstate = FLUSH_NEXT;
	   end // else: !if(dcache[flush_cnt...
	end 
	
	FLUSH_NEXT: begin // Increase flush counter
	   if (~flush_cnt.finish) begin
	      flush_cnt_en = 1;
	      if (ccif.ccwait[CPUID]) begin
		 nextstate = SNOOPY;
		 go_snoopy = 1;
	      end else begin
		 nextstate = FLUSH;
	      end
	   end else begin
	      nextstate = CACHE_HALT;
	   end
	end
	
	CACHE_HALT: begin
	   dcif.flushed = buffer_empty;
	   ccif.cctrans[CPUID] = 0;
	end
	
	SNOOPY: begin
	   nextstate = SNOOPY_DONE;
	   if ((dcache[snoopaddr.idx].block[0].tag == snoopaddr.tag) 
	       & (dcache[snoopaddr.idx].block[0].MESI != INVALID))begin
	      next_snoopy_set = 0;
	      nextstate = REPLY;
	   end else if ((dcache[snoopaddr.idx].block[1].tag == snoopaddr.tag) 
			& (dcache[snoopaddr.idx].block[1].MESI != INVALID)) begin
	      next_snoopy_set = 1;
	      nextstate = REPLY;
	   end
	end // case: SNOOPY
	
	REPLY: begin
	   nextstate = INV;
	   ccif.dWEN[CPUID] = 0;
	   if (~ccif.ccinv[CPUID] & ccif.ccwait[CPUID]) begin
	      nextstate = SUPPLY;
	      ccif.dWEN[CPUID] = 1;
	      ccif.cctrans[CPUID] = (dcache[snoopaddr.idx].block[snoopy_set].MESI == MODIFIED);
	   end else if (~ccif.ccwait[CPUID]) begin
	      nextstate = returnstate;
	   end
	end
	
	INV: begin
	   dcache_next[snoopaddr.idx].block[snoopy_set].MESI = INVALID;
	   lmif.invalid_bus = 1;
	   nextstate = SNOOPY_DONE;
	end
	
	SUPPLY: begin
	   if (~ccif.ccwait[CPUID]) begin
	      nextstate = returnstate;
	      dcache_next[snoopaddr.idx].block[snoopy_set].MESI = SHARED;
	   end
	   ccif.dWEN[CPUID] = 1;
	   ccif.cctrans[CPUID] = (dcache[snoopaddr.idx].block[snoopy_set].MESI == MODIFIED);
	   ccif.dstore[CPUID] = dcache[snoopaddr.idx].block[snoopy_set].data[snoopaddr.blkoff];
	end
	
	SNOOPY_DONE: begin
	   nextstate = returnstate;
	   ccif.cctrans[CPUID] = 0;
	end
      endcase // case (state)
   end // always_comb begin
endmodule // dcache

		 
	      
	   
	   
	   
	   
	   
	 
      

`include "cpu_types_pkg.vh"
`include "coherence_control_if.vh"

import cpu_types_pkg::*;

//This block behaves like a bus
module  coherence_control(
			  input logic nRST,
			  input logic CLK,
			  output logic fifo_empty,
			  coherence_control_if.snoopy_bus bus_if
			  );
   parameter BAD = 32'hBAD1BAD1;
   
   typedef enum 			 {
					  IDLE,
					  ARBITATION,
					  RM_REQUEST,
					  INV_REQUEST,
					  C2C,
					  M2C,
					  WB_MASTER,
					  WB_WAIT
					  }dcc_state;
   dcc_state state, next_state;
   
   logic 				 master, next_master, slave;
   assign slave = ~master;

   //Write_back buffer FIFO Signal
   logic 				 fifo_full;
   logic 				 fifo_wen, fifo_ren;
   word_t   [1:0] 		         fifo_out, fifo_in; // word 1 is the addr, word 0 is the data
   

   assign bus_if.dstore = fifo_out[0];
   
   //Write-back FIFO
   fifo FIFO(CLK, nRST, fifo_in, fifo_out, fifo_wen, fifo_ren, fifo_empty, fifo_full);
   assign fifo_ren = ~fifo_empty & ~bus_if.dwait;
   assign bus_if.dWEN = ~fifo_empty;
   
   //Next State Register
   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 state <= IDLE;
      end else begin
	 state <= next_state;
      end
   end

   //Master Register
   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
   	 master <= 0;
      end else begin
   	 master <= next_master;
      end
   end
  
   
   //Next State Logic
   always @ * begin
      next_state = state;
      next_master = master;
      
      case(state)
	IDLE: begin
	   if (bus_if.ccwrite | bus_if.cache_dWEN | bus_if.cache_dREN) begin
	      next_state = ARBITATION;
	   end
	end
	//Detect the Request and Decide the Master
	ARBITATION: begin
	   //Decide Next Master
	   if (bus_if.ccwrite[0] || bus_if.cache_dWEN[0] || bus_if.cache_dREN[0]) begin
	      next_master = 0;
	   end else begin
	      next_master = 1;
	   end
	   //Detect the Request Type
	   if (bus_if.ccwrite[next_master]) begin
	      next_state = INV_REQUEST;
	   end else if (bus_if.cache_dREN[next_master])begin
	      next_state = RM_REQUEST;
	   end else begin
	      next_state = WB_MASTER;
	   end
	end // case: ARBITATION
	//Send the Read Miss Request to slave(s)
	RM_REQUEST: begin
	   //Send Read Miss request to slave
	   if (bus_if.cache_dWEN[slave]) begin
	      next_state = C2C;
	   end else if (~bus_if.cctrans[slave]) begin
	      next_state = M2C;
	   end
	end
	//Send the Invalid Request to slave(s)
	INV_REQUEST: begin
	   if (~bus_if.cctrans[slave]) begin
	      next_state = IDLE;
	   end
	end
	//Slave to Master data transfers
	C2C: begin
	   if (!bus_if.cctrans[master]) begin
	      if (bus_if.cache_dWEN[master]) begin
		 next_state = WB_MASTER;
	      end else begin
		 if (!fifo_empty) begin
		    next_state = WB_WAIT;
		 end else begin
		    next_state = IDLE;
		 end
	      end
	   end
	end // case: C2C
	//RAM to Master data transfer
	M2C: begin
	   if (!bus_if.cctrans[master]) begin
	      if (bus_if.cache_dWEN[master]) begin
	   	 next_state = WB_MASTER;
	      end else begin
	   	 next_state = IDLE;	 
	      end
	   end
	end
	//Master perform write back
	WB_MASTER: begin
	   if (!bus_if.cctrans[master]) begin
	      next_state = WB_WAIT;
	   end
	end
	//Wait Write-back FIFO to be empty
	WB_WAIT: begin
	   if (fifo_empty) begin
	      next_state = IDLE;
	   end
	end
      endcase // case (state)
   end
   //State Logic
   always @ * begin
      bus_if.daddr = fifo_out[1];
      bus_if.dREN = 0;
      bus_if.cache_dload = {BAD, BAD};
      bus_if.ccinv = '0;
      bus_if.ccwait = '0;
      bus_if.cache_dwait = '1;
      bus_if.snoopy_addr = {bus_if.dcache_addr[0], bus_if.dcache_addr[1]};
      fifo_wen = 0;
      fifo_in = BAD;
      
      case(state)
	IDLE: begin
	end
	ARBITATION: begin
	end
	RM_REQUEST: begin
	   bus_if.ccwait[slave] = 1;
	end
	INV_REQUEST: begin
	   bus_if.ccwait[slave] = 1;
	   bus_if.ccinv[slave] = 1;
	   bus_if.cache_dwait[master] = bus_if.cctrans[slave];
	end
	C2C: begin
	   bus_if.ccwait[slave] = bus_if.cctrans[master];
	   bus_if.cache_dwait = '0;
 	   bus_if.cache_dload[master] = bus_if.dcache_data[slave];
	   fifo_wen = bus_if.cctrans[slave];
	   fifo_in = {bus_if.dcache_addr[master], bus_if.dcache_data[slave]};
	end
	M2C: begin
	   bus_if.daddr = bus_if.dcache_addr[master];
	   bus_if.dREN = bus_if.cache_dREN[master];
	   bus_if.cache_dwait[master] = bus_if.dwait;
	   bus_if.cache_dload[master] = bus_if.dload;
	end
	WB_MASTER: begin
	   bus_if.cache_dwait[master] = fifo_full;
	   fifo_wen = bus_if.cache_dWEN[master];
	   fifo_in = {bus_if.dcache_addr[master], bus_if.dcache_data[master]};
	end
	WB_WAIT: begin
	end
	 endcase
      end
endmodule

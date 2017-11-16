// 4-entry FIFO
`include "cpu_types_pkg.vh"
import cpu_types_pkg::*;

module fifo( input logic CLK, 
	     input logic  nRST, 
	     input 	  word_t [1:0] FIFO_in,
	     output 	  word_t [1:0] FIFO_out,
	     input logic  FIFO_WEN, FIFO_REN,
	     output logic FIFO_empty, FIFO_full
	     );

   logic 		 can_push, can_pop;
   logic [2:0] 		 counter, next_counter;               
   logic [1:0] 		 rd_ptr, wr_ptr, next_rd_ptr, next_wr_ptr;           // pointer to read and write addresses  
   word_t [3:0][1:0] 	      memory, memory_next;
   
   assign FIFO_empty = (counter == 0);
   assign FIFO_full  = (counter == 4);
   assign can_push = ~FIFO_full && FIFO_WEN;
   assign can_pop = ~FIFO_empty && FIFO_REN;
   assign FIFO_out = memory[rd_ptr];
   
   //Memory Reg
   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 memory <= '{default:'0};
      end else begin
	 memory <= memory_next;
      end
   end
   //Counter Reg
   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 counter <= 0;
      end else begin
	 counter <= next_counter;
      end
   end
   //Pointer Reg
   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 rd_ptr = 0;
	 wr_ptr = 0;
      end else begin
	 rd_ptr = next_rd_ptr;
	 wr_ptr = next_wr_ptr;
      end
   end
   //Push Logic
   always_comb begin
      memory_next = memory;
      if(can_push)begin
	 memory_next[wr_ptr] = FIFO_in;
      end
   end
   //Counter Logic
   always_comb begin
      next_counter = counter;

      if (can_push && can_pop) begin
	 next_counter = counter;
      end else if (can_push) begin
	 next_counter = counter + 1;
      end else if (can_pop) begin
	 next_counter = counter - 1;
      end
   end // always_comb begin

   //Pointer logic
   always_comb begin
      next_rd_ptr = rd_ptr;
      next_wr_ptr = wr_ptr;
      if (can_push) begin
	 next_wr_ptr = wr_ptr + 1;
      end
      if (can_pop) begin
	 next_rd_ptr = rd_ptr + 1;
      end
   end
endmodule // fifo


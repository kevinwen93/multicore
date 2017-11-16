`include "branch_prediction_if.vh"

module br_prediction(
		     input logic CLK,
		     input logic nRST,
		     branch_prediction_if.bp bpif
		     );
   
   typedef enum 		 logic [1:0] {
					    TAKE,
					    TAKE_LESS,
					    NTAKE_LESS,
					    NTAKE
					    }takeState;
   takeState    BTB[7:0];
   takeState    BTB_next;
   word_t       target_add[7:0];
   
   always_ff @(posedge CLK, negedge nRST) begin //table update
      if (!nRST) begin
	 BTB <= '{default:NTAKE};
	 target_add <= '{default:0};
      end else if(bpif.br & bpif.PC_en) begin
	 BTB[bpif.index_update] <= BTB_next;
	 target_add[bpif.index_update] <= bpif.br_target_I;
      end else begin
	 BTB <= BTB;
	 target_add <= target_add;
      end
   end
   
   always_comb begin //next state logic
      case (BTB[bpif.index_update])
	TAKE: begin
	   if (bpif.br_taken) begin
	      BTB_next = TAKE;
	   end else begin
	      BTB_next = TAKE_LESS;
	   end
	end
	TAKE_LESS: begin
	   if (bpif.br_taken) begin
	      BTB_next = TAKE;
	   end else begin
	      BTB_next = NTAKE_LESS;
	   end
	end
	NTAKE_LESS: begin
	   if (bpif.br_taken) begin
	      BTB_next = TAKE_LESS;
	   end else begin
	      BTB_next = NTAKE;
	   end
	end
	NTAKE: begin
	   if (bpif.br_taken) begin
	      BTB_next = NTAKE_LESS;
	   end else begin
	      BTB_next = NTAKE;
	   end
	end
      endcase // case BTB[index_update]
   end // always_comb begin
   
   assign bpif.br_target_O = target_add[bpif.index_I];
   assign bpif.predict = ((BTB[bpif.index_I] == TAKE) | (BTB[bpif.index_I] == TAKE_LESS))? 1 : 0;
   assign bpif.index_O = bpif.index_I;
   
endmodule
  
      

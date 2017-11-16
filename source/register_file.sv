`include "register_file_if.vh"
`include "cpu_types_pkg.vh"



module register_file(
  input CLK,
  input nRST,
  register_file_if.rf rfif
);
  import cpu_types_pkg::*;
  word_t [31:0]register;

   always_ff @(negedge CLK,negedge nRST)
     begin
	if (!nRST) begin
	   register <= '{default:'0};
	end else if (rfif.WEN && rfif.wsel) begin
	   register[rfif.wsel] <= rfif.wdat;
	end
     end
   assign rfif.rdat1 = register[rfif.rsel1];
   assign rfif.rdat2 = register[rfif.rsel2];
endmodule
   

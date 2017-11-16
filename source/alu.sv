`include "cpu_types_pkg.vh"
module alu(
 input logic [31:0]a,
 input logic [31:0]b,
 input logic [3:0]aluop,
 output logic negative,
 output logic overflow,
 output logic zero,
 output logic [31:0]out
);
   import cpu_types_pkg::*;
   assign zero = ~|out;
   assign negative = out[31];
   always_comb begin
      overflow = 0;   
      case(aluop)
	ALU_SLL:begin
	   out = a << b;//shift left
	end
	ALU_SRL:begin
	   out = a >> b;//shift right
	end
	ALU_AND:begin
	   out = a & b;//And
	end
	ALU_OR:begin
	   out = a | b;//Or
	end
	ALU_XOR:begin
	   out = a ^ b;//Xor
	end
	ALU_NOR:begin
	   out = ~(a | b);//nor
	end
	ALU_ADD:begin
	   out = $signed(a) + $signed(b);//Add
	   overflow = (!(a[31] ^ b[31])) & (out[31] ^ a[31]);
	end
	ALU_SUB:begin
	   out = $signed(a) - $signed(b);//Sub
	   overflow = (a[31] ^ b[31]) & !(b[31] ^ out[31]);
	end
	ALU_SLT:begin
	   out = ($signed(a) < $signed(b))? 1 : 0;
	end
	ALU_SLTU:begin
	   out = ($unsigned(a) < $unsigned(b))? 1 : 0;
	end
	default:out[31:0] = 'z;
      endcase // case (aluop)
   end // always_comb
endmodule // alu

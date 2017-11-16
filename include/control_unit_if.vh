`ifndef CONTROL_UNIT_IF_VH
`define CONTROL_UNIT_IF_VH

`include "cpu_types_pkg.vh"

interface control_unit_if;
   import cpu_types_pkg::*;
   
   opcode_t	opcode;
   funct_t	funct;
   logic	[1:0]PC_src;//2'b00 for normal +4, 2'b01 for branch, 2'b10 for jump, 2'b11 for register
   logic 	     Ext_src;// 1 for signed extend, 0 for zero extend
   logic 	     LUI_src;// 1 for lui, 0 in other case
   logic [2:0] 	     portb_src;//2'b00 for port b input to alu, 2'b01 for imm, 2'b10 for shamt 	     
   logic [1:0] 	     RegDst;//2'b00 for rd, 2'b01 for rt, 2'b10 for 31 
   aluop_t 	     ALU_op;//
   logic 	     MemWrite;//
   logic 	     MemRead;//   
   logic [1:0] 	     MemtoReg;//2'b00 from alu, 2'b01 from memory, 2'b10 from pc + 4
   logic 	     check_over;
   logic 	     mem_halt;
   logic 	     PC_EN;
   logic[1:0]	     bra;
   logic 	     rw_flag;
   logic             datomic; 	     
modport cu (
	    input  opcode, funct,
	    output PC_src, Ext_src, LUI_src, portb_src, RegDst, ALU_op, MemWrite, MemRead, MemtoReg, PC_EN, check_over, mem_halt, bra, rw_flag, datomic
	    );
 	     
    
endinterface
`endif

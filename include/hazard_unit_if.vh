`ifndef HAZARD_UNIT_IF_VH
`define HAZARD_UNIT_IF_VH

`include "cpu_types_pkg.vh"

interface hazard_unit_if;	
  import cpu_types_pkg::*;
  
  logic [1:0] forwarda_src;//2'b00 for no forward, 2'b01 for exmem_alu forward, 2'b10 for IntoMem forward
  logic [1:0] forwardb_src;
  logic stall;
  logic [1:0]memadd_forward;

  modport hu (
	output forwarda_src, forwardb_src, stall, memadd_forward
	);
endinterface
`endif

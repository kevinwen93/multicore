`ifndef LINK_MODULE_IF_VH
`define LINK_MODULE_IF_VH

`include "cpu_types_pkg.vh"

interface link_module_if;	
  import cpu_types_pkg::*;

   word_t             addr_cpu;
   word_t             addr_bus;
   logic 	      write_valid;
   logic	      update;
   logic 	      invalid_cpu;
   logic	      invalid_bus; 	      

   modport lm (
	       input  addr_cpu, addr_bus, update, invalid_cpu, invalid_bus,
	       output write_valid
	       );
endinterface
`endif

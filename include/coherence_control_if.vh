`ifndef COHERENCE_CONTROL_IF_VH
`define COHERENCE_CONTROL_IF_VH

`include "cpu_types_pkg.vh"

interface coherence_control_if;
   import cpu_types_pkg::*;
   
   // Cache side ports
   word_t [1:0] dcache_addr, dcache_data;
   word_t [1:0] snoopy_addr;
   logic [1:0] cctrans, ccwrite;
   logic [1:0] cache_dWEN, cache_dREN;
   logic [1:0] ccinv, ccwait;
   logic [1:0] cache_dwait;
   word_t [1:0] cache_dload;

   //RAM side ports
   word_t daddr, dstore, dload;
   logic       dWEN, dREN;
   logic       dwait;      
   
   modport snoopy_bus (
		       input  dcache_addr, dcache_data,
			      cctrans, ccwrite,
			      cache_dWEN, cache_dREN,
		              dwait, dload,
		       
		       output daddr, dstore, dWEN, dREN, cache_dload,
			      ccinv, ccwait, snoopy_addr,
			      cache_dwait
		       );
endinterface
`endif

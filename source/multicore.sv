/*
  Eric Villasenor
  evillase@gmail.com

  multicoretop block
  holds data path components, cache level
  and coherence
*/

module multicore (
  input logic CLK, nRST,
  output logic halt,
  cpu_ram_if.cpu scif
);

parameter PC0 = 0;
parameter PC1 = 'h200;
   logic       empty;
   
  // bus interface
  datapath_cache_if         dcif0 ();
  datapath_cache_if         dcif1 ();
  // coherence interface
  cache_control_if           ccif ();

  // map datapath
  datapath #(.PC_INIT(PC0)) DP0 (CLK, nRST, dcif0);
  datapath #(.PC_INIT(PC1)) DP1 (CLK, nRST, dcif1);
  // map caches
   // icache
   icache #(.CPUID(0)) ICACHE0(CLK, nRST, dcif0, ccif);
   // dcache
   dcache #(.CPUID(0)) DCACHE0(CLK, nRST, empty, dcif0, ccif);
   // icache
   icache #(.CPUID(1)) ICACHE1(CLK, nRST, dcif1, ccif);
   // dcache
   dcache #(.CPUID(1)) DCACHE1(CLK, nRST, empty, dcif1, ccif);
  //caches #(.CPUID(0))       CM0 (CLK, nRST, dcif0, ccif);
  //caches #(.CPUID(1))       CM1 (CLK, nRST, dcif1, ccif);
  // map coherence
  memory_control            CC (CLK, nRST, empty, ccif);

  // interface connections
  assign scif.memaddr = ccif.ramaddr;
  assign scif.memstore = ccif.ramstore;
  assign scif.memREN = ccif.ramREN;
  assign scif.memWEN = ccif.ramWEN;

  assign ccif.ramload = scif.ramload;
  assign ccif.ramstate = scif.ramstate;

  assign halt = dcif0.flushed & dcif1.flushed;
endmodule

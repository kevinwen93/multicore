/*
  Eric Villasenor
  evillase@gmail.com

  this block holds the i and d cache
*/


module caches (
  input logic CLK, nRST,
  datapath_cache_if dcif,
  cache_control_if ccif
);
  parameter CPUID = 0;
   
   // icache
   icache #(.CPUID(CPUID)) ICACHE(CLK, nRST, dcif.icache, ccif.icache);
   // dcache
   dcache #(.CPUID(CPUID)) DCACHE(CLK, nRST, dcif.dcache, ccif.dcache);

  // dcache invalidate before halt handled by dcache when exists
  //assign dcif.flushed = dcif.halt; // 

  //singlecycle
  //assign dcif.ihit = (dcif.imemREN) ? ~ccif.iwait : 0;
  //assign dcif.dhit = (dcif.dmemREN|dcif.dmemWEN) ? ~ccif.dwait : 0;
  //assign dcif.imemload = ccif.iload;
  //assign dcif.dmemload = ccif.dload;


  //assign ccif.iREN = dcif.imemREN;
  //assign ccif.dREN = dcif.dmemREN;
  //assign ccif.dWEN = dcif.dmemWEN;
  //assign ccif.dstore = dcif.dmemstore;
  //assign ccif.iaddr = dcif.imemaddr;
  //assign ccif.daddr = dcif.dmemaddr;

endmodule

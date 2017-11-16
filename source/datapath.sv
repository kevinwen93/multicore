/*
  Eric Villasenor
  evillase@gmail.com

  datapath contains register file, control, hazard,
  muxes, and glue logic for processor
*/

// data path interface

// alu op, mips op, and instruction type
`include "cpu_types_pkg.vh"

// register file if
`include "pipeline_reg_pkg.vh"


module datapath (
		 input logic CLK, nRST,
		 datapath_cache_if.dp dpif
		 );
   
   // import types
   import cpu_types_pkg::*;
   import pipeline_reg_pkg::*;
   // pc init
   parameter PC_INIT = 0;
   parameter CPUID = 0;
   //if import
   hazard_unit_if huif();
   register_file_if rfif();
   control_unit_if cuif();
   branch_prediction_if bpif();

   //pipeline reg
   ifid_p ifid;
   idex_p idex;
   exmem_p exmem;
   mem_p mem;

   //decoding port
   j_t j_inst;
   i_t i_inst;
   r_t r_inst;
   
   //port init
   logic 		     PC_en, negative, overflow, zero, halt;
   word_t PC_next, PC, out, portb_mux_out, forward_a, forward_b, memadd_forward;
   logic [2:0] 		     PC_src;
   word_t PC_plus4, PC_branch, PC_reg, PC_jump;
   //units map  
   register_file RF(CLK, nRST, rfif);
   
   alu ALU(forward_a, forward_b, idex.ALU_op, negative, overflow, zero, out);
   
   control_unit CU(cuif);
   
   hazard_unit HU(idex.rs, idex.rt_hazard, idex.MemRead, idex.MemWrite,r_inst.rs, r_inst.rt, 
		  exmem.RegWEN, exmem.RegDst_out, mem.RegWEN, mem.RegDst_out, idex.MemWrite, idex.rt, idex.datomic, huif);
   
   br_prediction BP(CLK, nRST, bpif);

   //flush signal
   logic 		     ifid_en, idex_en, exmem_en, mem_en;//pipeline regs enbale signals
   logic 		     ifid_flush, idex_flush, exmem_flush;// pipeline regs flush signals
   logic 		     oneState_flush, threeStates_flush;//oneState flush idex, Threestates flush ifid, idex, exmem
   logic 		     predict_fail; //branch perdict related signal

   /*************************************
    Pipeline Regs Enable logic (related to ram lantency)
   ***************************************/
   assign ifid_en = ~mem.halt & 
		    (~(huif.stall & ~predict_fail) & 
		     ~((PC_src == 3'b010 | PC_src == 3'b011 | PC_src == 3'b100) & ~PC_en)) & 
		    (~(exmem.MemRead | exmem.MemWrite) | dpif.dhit);
   assign ifid_flush = (~PC_en | oneState_flush | threeStates_flush);
   assign idex_en = ~mem.halt & 
		    (~(exmem.MemRead | exmem.MemWrite) | dpif.dhit);
   assign idex_flush = (threeStates_flush & PC_en) | (huif.stall & ~predict_fail);
   assign exmem_en = ~mem.halt & ~((PC_src == 3'b101 | PC_src == 3'b001) & ~PC_en) & 
		    (~(exmem.MemRead | exmem.MemWrite) | dpif.dhit);
   assign exmem_flush = threeStates_flush & PC_en;
   assign mem_en = ~mem.halt & 
		    (~(exmem.MemRead | exmem.MemWrite) | dpif.dhit);
	
	    
   //reg out portal
   regbits_t RWD_out;
   word_t IntoMem, IntoLUI;

   //*********************************PC Select Logic*******************************//
   
   //PC Reg
   always_ff @(posedge CLK,negedge nRST) begin
      if (!nRST) begin
	 PC <= PC_INIT;
      end else if(PC_en) begin
	 PC <= PC_next;
      end
   end
     
   logic 		     br;
   always_comb begin
      PC_src = 3'b000;//default state, nextPC = PC_plus4
      threeStates_flush = 0;
      oneState_flush = 0;

      //Priority: perdict_fail > jump > branch prediction > default
      if(predict_fail) begin
	 threeStates_flush = 1;
	 PC_src = br? 3'b001 : 3'b101; //if prediction fail goes back to correct PC and do three states flush
      end else if(cuif.PC_src == 2'b11 | cuif.PC_src == 2'b10) begin
	 oneState_flush = 1;
	 PC_src = (cuif.PC_src  == 2'b11)? 3'b011 : 3'b010;//Jump selection
      end else if((cuif.bra != 0) & bpif.predict) begin //prediction
	 oneState_flush = 1;
	 PC_src = 3'b100;//select from prediction
      end
   end

   //**********************************************************************************//

   /**************************************************
                 Instrction Decoding
    **************************************************/
   assign j_inst = j_t'(ifid.instr);//decode the inst(instrustion) in j-type style
   assign i_inst = i_t'(ifid.instr);//decode the inst in i-type style
   assign r_inst = r_t'(ifid.instr);//decode the inst in r-type style
     
   //***********************************Extender*********************************
   word_t signedExt, zeroExt, shamtExt, luiExt, branchExt;
   logic [27:0] 	     jumpExt;
   //Extender assignment
   assign signedExt = !idex.imm[15] ? {16'h0000, idex.imm} : {16'hFFFF, idex.imm};
   assign zeroExt = {16'h0000, idex.imm};
   assign jumpExt = {j_inst.addr, 2'b00};
   assign luiExt = {idex.imm, 16'h0000};
   assign shamtExt = {27'b0,idex.shamt};
   assign branchExt = !exmem.imm[15] ? {16'h0000, exmem.imm} : {16'hFFFF, exmem.imm};
         
   //***********************************PC Block*************************************//
   assign PC_en = dpif.ihit & ~mem.halt & 
		  ~(huif.stall & ~predict_fail) & (~(exmem.MemRead | exmem.MemWrite) | dpif.dhit); // PC enable logic, most related to ram latency
   word_t 		     pc_temp;
   assign pc_temp = ifid.pc_plus4 - 4;
   //PC caculation
   assign PC_plus4 = PC + 4;
   assign PC_jump = {pc_temp[31:28], jumpExt};
   assign PC_branch = exmem.pc_plus4 + (branchExt << 2);
   assign PC_reg = rfif.rdat1;
   //PC mux
   word_t PC_out;
   assign PC_next = PC_out;
   always_comb begin
      PC_out = PC_plus4;
      casez(PC_src)
	3'b001:begin
	   PC_out = PC_branch;
	end
	3'b010:begin
	   PC_out = PC_jump;
	end
	3'b011:begin
	   PC_out = PC_reg;
	end
	3'b100:begin
	   PC_out = bpif.br_target_O;
	end
	3'b101:begin
	   PC_out = exmem.pc_plus4;
	end
      endcase
   end // always_comb
   
   //*************************************************************************************//

   //************************************//
   //  Instruction Fetch Unit Register  //
   //***********************************//

   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 ifid <= 0;
      end else if (ifid_en) begin
	 if (ifid_flush) begin
	    ifid.instr <= 0;
	    ifid.pc_plus4 <= 0;
	 end else begin
	    ifid.instr <= dpif.imemload;
	    ifid.pc_plus4 <= PC_plus4;
	 end
      end else begin
	 ifid <= ifid;
      end
   end
   
   //***********************************Control Block************************************//
   assign cuif.opcode = r_inst.opcode;
   assign cuif.funct = r_inst.funct;
   //***********************************************************************************//


   //************************************//
   //         Decode Register           //
   //***********************************//

   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 idex <= 0;	 
      end else if(idex_en) begin // if (!nRST)
	 if (idex_flush) begin
	    idex <= 0;
	 end else begin
	    idex.rdat_1 <= rfif.rdat1;
	    idex.rdat_2 <= rfif.rdat2;
	    idex.rt_hazard <= ((cuif.RegDst != 2'b01) | (cuif.datomic & cuif.MemWrite))? r_inst.rt : 0;
	    idex.rt <= r_inst.rt;
	    idex.rd <= r_inst.rd;
	    idex.rs <= r_inst.rs;
	    idex.imm <= i_inst.imm;
	    idex.shamt <= r_inst.shamt;
	    idex.jaddr <= j_inst.addr;
	    idex.pc_plus4 <= ifid.pc_plus4;
	    idex.bra <= cuif.bra;
	    idex.predict <= bpif.predict;
	    idex.index <= bpif.index_O;
	    idex.br_target <= bpif.br_target_O;
	    idex.LUI_src <= cuif.LUI_src;
	    idex.Ext_src <= cuif.Ext_src;
	    idex.portb_src <= cuif.portb_src;
	    idex.PC_src <= cuif.PC_src;
	    idex.RegWEN <= (cuif.MemtoReg != 2'b01)? cuif.rw_flag : 1;  
	    idex.RegDst <= cuif.RegDst;
	    idex.ALU_op <= cuif.ALU_op;
	    idex.MemWrite <= cuif.MemWrite;
	    idex.MemRead <= cuif.MemRead;
	    idex.MemtoReg <= cuif.MemtoReg;
	    idex.check_over <= cuif.check_over;
	    idex.mem_halt <= cuif.mem_halt;
	    idex.datomic <= cuif.datomic;
	 end
      end else begin // else: !if(!nRST)
	 idex <= idex;
      end // else: !if(!nRST)
   end // always_ff @  
   
   //***********************************//
   //           HALT  logic            //
   //**********************************//

   assign halt = (idex.check_over & overflow) | idex.mem_halt;

   //***********************************//
   //Memory Operation / Memory Output Reg
   //**********************************//

   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 exmem <= 0;
      end else if (exmem_en) begin // if (!nRST)
	 if (exmem_flush) begin
	    exmem <= 0;
	 end else begin 
	    exmem.imm <= idex.imm;
	    exmem.RegWEN <= idex.RegWEN;
	    exmem.zero <= zero;
	    exmem.overflow <= overflow;
	    exmem.bra <= idex.bra;
	    exmem.predict <= idex.predict;
	    exmem.index <= idex.index;
	    exmem.br_target <= idex.br_target;
	    exmem.MemtoReg <= idex.MemtoReg;
	    exmem.MemRead <= idex.MemRead;
	    exmem.MemWrite <= idex.MemWrite;
	    exmem.alu_out <= out;
	    exmem.RegDst_out <= RWD_out;
	    exmem.pc_plus4 <= idex.pc_plus4;
	    exmem.rdat_2 <= memadd_forward;
	    exmem.datomic <= idex.datomic;
	    exmem.halt <= halt;
	 end // else: !if(exmem_flush)
      end else begin
	 exmem <= exmem;

      end
   end // always_ff @ (posedge CLK, negedge n_RST)


  //*******************************Branch Prediction Check*******************************//
   always_comb begin
      br = 0;
      predict_fail = 1;
      casez(exmem.bra)
	2'b01:begin
	   br = exmem.zero;
	end
	2'b10: begin
	   br = ~exmem.zero;
	end //
      endcase // casez (exme.bra)
      
      if (((br == exmem.predict) & ((br & (PC_branch == exmem.br_target)) 
	  | !br)) | !exmem.bra) begin
	 predict_fail = 0;
      end
   end // always_comb begin   
   //***********************************************************************************//
   
   //***********************************//
   //       Memory Output Reg
   //**********************************//
   always_ff @(posedge CLK, negedge nRST) begin
      if (!nRST) begin
	 mem <= 0;
      end else if (mem_en) begin
	 mem.MemtoReg <= exmem.MemtoReg;
	 mem.RegWEN <= exmem.RegWEN;
	 mem.halt <= exmem.halt;
	 mem.dload <= dpif.dmemload;
	 mem.alu_out <= exmem.alu_out;
	 mem.RegDst_out <= exmem.RegDst_out;
	 mem.pc_plus4 <= exmem.pc_plus4;
	 mem.imm <= exmem.imm;
      end
   end // always_ff @ (posedge CLK, negedge nRST)
   
   
   //********************************ALU MUX SET*****************************************//

   //************* Foward Mux*******************//
   always_comb begin
      memadd_forward = idex.rdat_2;
      casez(huif.memadd_forward)
	2'b01:begin
	   memadd_forward = exmem.alu_out;
	end
	2'b10:begin
	   memadd_forward = IntoMem;
	end
      endcase // casez (huif.memadd_forward)
   end // always_comb begin
   
   always_comb begin
      forward_a = idex.rdat_1;
      casez(huif.forwarda_src)
	2'b01:begin
	   forward_a = exmem.alu_out;
	end
	2'b10:begin
	   forward_a = IntoMem;
	end
      endcase // casez (XXX)
   end

   always_comb begin
      forward_b = portb_mux_out;
      casez(huif.forwardb_src)
	2'b01:begin
	   forward_b = exmem.alu_out; 
	end
	2'b10:begin
	   forward_b = IntoMem;
	end
      endcase // casez (XXX)
   end // always_comb begin

   //*******************************************//
   
   //Reg Write Dst Mux
   always_comb begin
      RWD_out = idex.rd;
      casez(idex.RegDst)
	2'b01:begin
	   RWD_out = idex.rt;
	end
	2'b10:begin
	   RWD_out = 5'd31;
	end
      endcase // casez (CU.RegDst)
   end // always_comb
   
   //Reg Write Port Mux
 
   always_comb begin
      IntoMem = mem.alu_out;
      casez(mem.MemtoReg)
	2'b01:begin
	   IntoMem = mem.dload;
	end
	2'b10:begin
	   IntoMem = mem.pc_plus4;
	end
      endcase // casez (MemtoReg)
   end // always_comb

   //LUI Mux
   assign portb_mux_out = idex.LUI_src? luiExt : IntoLUI; 
   
   //signed/zero Extender select Mux
   word_t extended_imm;
   assign extended_imm = idex.Ext_src? signedExt : zeroExt;

   //ALU Port b select Mux
   always_comb begin
      IntoLUI = idex.rdat_2;
      casez(idex.portb_src)
	2'b01:begin
	   IntoLUI = extended_imm;
	end
	2'b10:begin
	   IntoLUI = shamtExt;
	end
      endcase // casez (CU.portb_scr)
   end // always_comb

   //*****************************Register File I/O Assignment***************************//
   assign rfif.WEN = mem.RegWEN;
   assign rfif.wsel = mem.RegDst_out;
   assign rfif.rsel1 = r_inst.rs;
   assign rfif.rsel2 = r_inst.rt;
   assign rfif.wdat = IntoMem;
   //************************************************************************************//

   //*******************************Datapath I/O Assignment*****************************//
   assign dpif.halt = mem.halt;
   assign dpif.imemREN = 1;
   assign dpif.imemaddr = PC;
   assign dpif.dmemREN = exmem.MemRead;
   assign dpif.dmemWEN = exmem.MemWrite;
   assign dpif.dmemstore = exmem.rdat_2;
   assign dpif.dmemaddr = exmem.alu_out;
   assign dpif.datomic = exmem.datomic;
   //***********************************************************************************//
   
   //************************Branch Predict Block I/O Assignment************************//
   assign bpif.br = (exmem.bra != 0);
   assign bpif.index_I = i_inst.imm[2:0];
   assign bpif.index_update = exmem.index;
   assign bpif.br_taken = br;
   assign bpif.br_target_I = PC_branch;
   assign bpif.PC_en = PC_en;
   //**********************************************************************************//
    
endmodule


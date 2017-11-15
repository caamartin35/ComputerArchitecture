/*
 *
 * Redistributions of any form whatsoever must retain and/or include the
 * following acknowledgment, notices and disclaimer:
 *
 * This product includes software developed by Carnegie Mellon University. 
 *
 * Copyright (c) 2004 by Babak Falsafi and James Hoe,
 * Computer Architecture Lab at Carnegie Mellon (CALCM), 
 * Carnegie Mellon University.
 *
 * This source file was written and maintained by Jared Smolens 
 * as part of the Two-Way In-Order Superscalar project for Carnegie Mellon's 
 * Introduction to Computer Architecture course, 18-447. The source file
 * is in part derived from code originally written by Herman Schmit and 
 * Diana Marculescu.
 *
 * You may not use the name "Carnegie Mellon University" or derivations 
 * thereof to endorse or promote products derived from this software.
 *
 * If you modify the software you must place a notice on or within any 
 * modified version provided or made available to any third party stating 
 * that you have modified the software.  The notice shall include at least 
 * your name, address, phone number, email address and the date and purpose 
 * of the modification.
 *
 * THE SOFTWARE IS PROVIDED "AS-IS" WITHOUT ANY WARRANTY OF ANY KIND, EITHER 
 * EXPRESS, IMPLIED OR STATUTORY, INCLUDING BUT NOT LIMITED TO ANYWARRANTY 
 * THAT THE SOFTWARE WILL CONFORM TO SPECIFICATIONS OR BE ERROR-FREE AND ANY 
 * IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, 
 * TITLE, OR NON-INFRINGEMENT.  IN NO EVENT SHALL CARNEGIE MELLON UNIVERSITY 
 * BE LIABLE FOR ANY DAMAGES, INCLUDING BUT NOT LIMITED TO DIRECT, INDIRECT, 
 * SPECIAL OR CONSEQUENTIAL DAMAGES, ARISING OUT OF, RESULTING FROM, OR IN 
 * ANY WAY CONNECTED WITH THIS SOFTWARE (WHETHER OR NOT BASED UPON WARRANTY, 
 * CONTRACT, TORT OR OTHERWISE).
 *
 */

//////
////// MIPS 447: A single-cycle MIPS ISA simulator
//////

// Include the MIPS constants
`include "mips_defines.vh"
`include "internal_defines.vh"

////
//// The MIPS standalone processor module
////
////   clk          (input)  - The clock
////   inst_addr    (output) - Address of instruction to load
////   inst         (input)  - Instruction from memory
////   inst_excpt   (input)  - inst_addr not valid
////   mem_addr     (output) - Address of data to load
////   mem_data_in  (output) - Data for memory store
////   mem_data_out (input)  - Data from memory load
////   mem_write_en (output) - Memory write mask
////   mem_excpt    (input)  - mem_addr not valid
////   halted       (output) - Processor halted
////   reset        (input)  - Reset the processor
////   

module mips_core(/*AUTOARG*/
   // Outputs
   inst_addr, mem_addr, mem_data_in, mem_write_en, halted,
   // Inputs
   clk, inst_excpt, mem_excpt, inst, mem_data_out, rst_b
   );
   
   parameter text_start  = 32'h00400000; /* Initial value of $pc */

   // Core Interface
   input         clk, inst_excpt, mem_excpt;
   output [29:0] inst_addr;
   output [29:0] mem_addr;
   input  [31:0] inst, mem_data_out;
   output [31:0] mem_data_in;
   output [3:0]  mem_write_en;
   output        halted;
   input         rst_b;

   // Internal signals
   wire [31:0]   pc, nextpc;
   wire          exception_halt, syscall_halt, internal_halt;
   wire          load_epc, load_bva, load_bva_sel;
   wire [31:0]   rt_data, rs_data, rd_data, alu__out, r_v0;
   wire [31:0]   epc, cause, bad_v_addr;
   wire [4:0]    cause_code;
   wire [31:0] 	 src1_mux_out, src2_mux_out;
   wire [31:0] 	 processed_data;
   wire [31:0] 	 controller_out;
   wire [31:0] 	 instruction_dec;
   
   
	 
   // Decode signals
   wire [31:0]   dcd_se_imm, dcd_se_offset, dcd_e_imm, dcd_se_mem_offset;
   wire [5:0]    dcd_op, dcd_funct2;
   wire [4:0]    dcd_rs, dcd_funct1, dcd_rt, dcd_rd, dcd_shamt;
   wire [15:0]   dcd_offset, dcd_imm;
   wire [25:0]   dcd_target;
   wire [19:0]   dcd_code;
   wire          dcd_bczft;
   wire [31:0] 	 shamt_extended, target_extended;
   wire [31:0] 	 target_addr;
   wire 	 loading, loading_ex, loading_mem, loading_wb;
   
   
   
   
   assign        inst_addr = pc[31:2];

   // Instruction decoding
   assign        dcd_op = instruction_dec[31:26];    // Opcode
   assign        dcd_rs = instruction_dec[25:21];    // rs field
   assign        dcd_rt = instruction_dec[20:16];    // rt field
   assign        dcd_shamt = instruction_dec[10:6];  // Shift amount
   assign        dcd_bczft = instruction_dec[16];    // bczt or bczf?
   assign        dcd_funct1 = instruction_dec[4:0];  // Coprocessor 0 function field
   assign        dcd_funct2 = instruction_dec[5:0];  // funct field; secondary opcode
   assign        dcd_offset = instruction_dec[15:0]; // offset field
        // Sign-extended offset for branches
   assign        dcd_se_offset = { {14{dcd_offset[15]}}, dcd_offset, 2'b00 };
        // Sign-extended offset for load/store
   assign        dcd_se_mem_offset = { {16{dcd_offset[15]}}, dcd_offset };
   assign        dcd_imm = instruction_dec[15:0];        // immediate field
   assign        dcd_e_imm = { 16'h0, dcd_imm };  // zero-extended immediate
        // Sign-extended immediate
   assign        dcd_se_imm = { {16{dcd_imm[15]}}, dcd_imm };
   assign        dcd_target = instruction_dec[25:0];     // target field
   assign        dcd_code = instruction_dec[25:6];       // Breakpoint code
   assign        shamt_extended[31:5] = 0;
   assign        shamt_extended[4:0] = dcd_shamt;
   assign        target_extended[31:26] = 0;
   assign        target_extended[25:0] = dcd_target;
   assign        target_addr = ((target_extended << 2) | (pc & 32'hF0000000));
   

			
   
   // synthesis translate_off
   always @(posedge clk) begin
     // useful for debugging, you will want to comment this out for long programs
     if (rst_b) begin
       //$display ( "=== Simulation Cycle %d ===", $time );
       //$display ( "[pc=%x, inst=%x] [op=%x, rs=%d, rt=%d, rd=%d, imm=%x, f2=%x] [reset=%d, halted=%d]",
         //          pc, inst, dcd_op, dcd_rs, dcd_rt, dcd_rd, dcd_imm, dcd_funct2, ~rst_b, halted);
     end
   end
   // synthesis translate_on

   // Let Verilog-Mode pipe wires through for us.  This is another example
   // of Verilog-Mode's power -- undeclared nets get AUTOWIREd up when we
   // run 'make auto'.
   
   //connecting wires
   wire [31:0] rs_to_src1mux;
   wire [31:0] imm_e_to_src2mux;
   wire [31:0] imm_se_to_src2mux;
   wire [31:0] rt_to_src2mux;
   wire [31:0] shamt_to_src1mux;
   wire [31:0] alu_to_mem;
   wire [31:0] rt_to_mem;
   wire [31:0] procData_to_rdmux;
   wire [31:0] after_alu_mem_to_rdmux;
   wire [31:0] mul_to_mem;
   wire [31:0] after_mul_mem_to_rdmux;
   wire [31:0] mul__out;
   wire [31:0] rt_mux_out, rs_mux_out;
   wire [31:0] pc_mux_out;
   
   
   //control signals
   wire [3:0]		alu__sel, alu_sel_ex; 		
   wire			ctrl_RI;		
   wire			ctrl_Sys;		
   wire			ctrl_we, ctrl_we_ex, ctrl_we_mem, ctrl_we_wb;
   wire [1:0] 		src1_sel, src1_sel_ex; 		
   wire [1:0] 		src2_sel, src2_sel_ex;
   wire [1:0] 		rd_sel, rd_sel_ex, rd_sel_mem, rd_sel_wb;
   wire 		memext_sel, memext_sel_ex, memext_sel_mem;
   wire [1:0] 		word_size, word_size_ex, word_size_mem;
   wire 		store_en, store_en_ex, store_en_mem;
   wire 		mul_en, mul_en_ex, mul_en_mem, mul_en_wb;
   wire [2:0] 		mul_sel, mul_sel_ex;
   wire 		ld_pipeline_regs;
   wire [1:0]		rs_sel, rt_sel;
   wire [4:0] 		dcd_rd_ex, dcd_rd_mem, dcd_rd_wb;
   wire [1:0] 		timerr;
   wire 		start_timerr;
   wire 		stall;
   wire [1:0] 		pc_sel;
   wire [31:0] 		branch_out, branch_out_mem, branch_out_wb;
   wire [31:0] 		pc_dec, pc_ex;
   wire [31:0] 		ex_feedback, mem_feedback, wb_feedback;
		
   //Branch predictor wires
   wire 		pc_ready, taken_pc;
   wire [31:0] 		new_pc;
   wire 		flush_dec, flush_ex;
   wire [3:0] 		branch_sel, branch_sel_ex;
   wire 		branch_en, branch_en_ex, branch_en_mem, branch_en_wb;
   wire 		choice;
   wire [11:0] 		GHR;
   
   //Branch predictor
   brnchPredictReg BPreg(
			 //outputs
			 .new_pc(new_pc),
			 .flush_dec(flush_dec),
			 .flush_ex(flush_ex),
			 .GHR(GHR),
			 //inputs
			 .choice(choice), //0 is global, 1 is local
			 .taken_pc(taken_pc),
			 .pc_ready(pc_ready),
			 .target_addr(target_addr),
			 .rs_data(rs_mux_out),
			 .current_pc(pc),
			 .branch_pc(pc_dec),
			 .offset(dcd_se_imm),
			 .pc_sel(pc_sel),
			 .stall(stall),
			 .clk(clk),
			 .rst_b(rst_b));

   predictorChooser pre_choose(
			       //outputs
			       .choice(choice),
			       //inputs
			       .GHR(GHR));
   
   //Branch Executer
   branchEx bex(
		//outputs
		.branch_out(branch_out),
		.pc_ready(pc_ready),
		.taken_pc(taken_pc),
		//inputs
		.rs(rs_to_src1mux),
		.rt(rt_to_src2mux),
		.link_pc(pc_ex + 4),
		.branch_en(branch_en_ex),
		.branch_sel(branch_sel_ex));
   

   //CHANGE THIS FOR STALLING
   assign ld_pipeline_regs = ~stall;



   valid_logic vl(.rt_sel(rt_sel),
		  .rs_sel(rs_sel),
		  .stall(stall),
		  .loading(loading_ex),
		  .rs_num(dcd_rs),
		  .rt_num(dcd_rt),
		  .rd_num(dcd_rd),
		  .clk(clk),
		  .rst_b(rst_b),
		  .flush_ex(flush_ex));

   //loading register - tells when we are loading so we know to stall if need be
   register #(1, 0) isLoading(loading_ex, loading, clk, 1'b1, rst_b, 1'b0);
   
   
   //Pipeline stage data registers

   //FETCH
   register #(32, text_start) pc_fetch(pc, new_pc, clk, ~internal_halt, rst_b, 1'b0);
   
   //DECODE
   register ir_dec(instruction_dec, inst, clk, ld_pipeline_regs, rst_b, flush_dec | flush_ex);
   register pc_reg_dec(pc_dec, pc, clk, ld_pipeline_regs, rst_b, flush_dec | flush_ex);
   
   //EXECUTE
   register rs_ex(rs_to_src1mux, rs_mux_out, clk, ld_pipeline_regs, rst_b, flush_ex);
   register imm_e_ex(imm_e_to_src2mux, dcd_e_imm, clk, ld_pipeline_regs, rst_b, flush_ex);
   register imm_se_ex(imm_se_to_src2mux, dcd_se_imm, clk, ld_pipeline_regs, rst_b, flush_ex);
   register rt_ex(rt_to_src2mux, rt_mux_out, clk, ld_pipeline_regs, rst_b, flush_ex);
   register shift_amnt_ex(shamt_to_src1mux, shamt_extended, clk, ld_pipeline_regs, rst_b, flush_ex);
   register pc_reg_ex(pc_ex, pc_dec, clk, ld_pipeline_regs, rst_b, flush_ex);
   
     
   //MEM
   register alu_mem(alu_to_mem, alu__out, clk, 1'b1, rst_b, 1'b0);
   register rt_mem(rt_to_mem, rt_to_src2mux, clk, 1'b1, rst_b, 1'b0);
   register mul_mem(mul_to_mem, mul__out, clk, 1'b1, rst_b, 1'b0);
   register branch_out_reg_mem(branch_out_mem, branch_out, clk, 1'b1, rst_b, 1'b0);
   
   //WB (before rdmux)
   register after_process(procData_to_rdmux, processed_data, clk, 1'b1, rst_b, 1'b0);
   register after_alu_mem(after_alu_mem_to_rdmux, alu_to_mem, clk, 1'b1, rst_b, 1'b0);
   register after_mul_mem(after_mul_mem_to_rdmux, mul_to_mem, clk, 1'b1, rst_b, 1'b0);
   register after_branch_out_mem(branch_out_wb, branch_out_mem, clk, 1'b1, rst_b, 1'b0);
   
   
   //pipeline stage ctrl registers

   //EXECUTE
   
   ctrl_ex_register ctrl_ex_ex(alu_sel_ex, alu__sel, src1_sel_ex, src1_sel, src2_sel_ex, src2_sel, mul_en_ex, mul_en, mul_sel_ex, mul_sel, branch_en_ex, branch_en, branch_sel_ex, branch_sel, clk, ld_pipeline_regs, rst_b, flush_ex);

   //MEM
   register #(1, 0) mul_en_mem_reg(mul_en_mem, mul_en_ex, clk, 1'b1, rst_b, 1'b0);
   register #(1, 0) branch_en_mem_reg(branch_en_mem, branch_en_ex, clk, 1'b1, rst_b, 1'b0);
   register #(1, 0) loading_mem_reg(loading_mem, loading_ex, clk, 1'b1, rst_b, 1'b0);
   ctrl_mem_register ctrl_ex_mem(memext_sel_ex, memext_sel, word_size_ex, word_size, store_en_ex, store_en, clk, 1'b1, rst_b);
   ctrl_mem_register ctrl_mem_mem(memext_sel_mem, memext_sel_ex, word_size_mem, word_size_ex, store_en_mem, store_en_ex, clk, 1'b1, rst_b);
   

   //WB
   register #(1, 0) mul_en_wb_reg(mul_en_wb, mul_en_mem, clk, 1'b1, rst_b, 1'b0);
   register #(1, 0) branch_en_wb_reg(branch_en_wb, branch_en_mem, clk, 1'b1, rst_b, 1'b0);
   register #(1, 0) loading_wb_reg(loading_wb, loading_mem, clk, 1'b1, rst_b, 1'b0);
   ctrl_wb_register ctrl_ex_wb(ctrl_we_ex, ctrl_we, rd_sel_ex, rd_sel, dcd_rd_ex, dcd_rd, clk, 1'b1, rst_b, flush_ex);
   ctrl_wb_register ctrl_mem_wb(ctrl_we_mem, ctrl_we_ex, rd_sel_mem, rd_sel_ex, dcd_rd_mem, dcd_rd_ex, clk, 1'b1, rst_b, 1'b0);
   ctrl_wb_register ctrl_wb_wb(ctrl_we_wb, ctrl_we_mem, rd_sel_wb, rd_sel_mem, dcd_rd_wb, dcd_rd_mem, clk, 1'b1, rst_b, 1'b0);
   
   always @(posedge clk) begin
      /*$display($time, " DATA: \nIF: pc=%x inst=%x \nID: ir=%x \nEX: rs=%x, rt=%x, i_e=%x, i_se=%x, shft_amnt=%x, alu_out=%x \nMEM: mul=%x, alu=%x, rt=%x \nWB: a_mul=%x, a_alu=%x, a_proc=%x\n\n CTRL: \nID: alu_sel=%x, src1_sel=%x, src2_sel=%x, mul_en=%x, mul_sel=%x, memext=%x, word_size=%x, store_en=%x, ctrl_we=%x, rd_sel=%x, rd_num=%x \nEX: alu_sel=%x, src1_sel=%x, src2_sel=%x, mul_en=%x, mul_sel=%x, memext=%x, word_size=%x, store_en=%x, ctrl_we=%x, rd_sel=%x, rd_num=%x \nMEM: memext=%x, word_size=%x, store_en=%x, ctrl_we=%x, rd_sel=%x, rd_num=%x \nWB: ctrl_we=%x, rd_sel=%x, rd_num=%x\n\n valids: %b\n time_set: %d\n\n", pc, inst, instruction_dec, rs_to_src1mux, rt_to_src2mux, imm_e_to_src2mux, imm_se_to_src2mux, shamt_to_src1mux, alu__out, mul_to_mem, alu_to_mem, rt_to_mem, after_mul_mem_to_rdmux, after_alu_mem_to_rdmux, procData_to_rdmux, alu__sel, src1_sel, src2_sel, mul_en, mul_sel, memext_sel, word_size, store_en, ctrl_we, rd_sel, dcd_rd, alu_sel_ex, src1_sel_ex, src2_sel_ex, mul_en_ex, mul_sel_ex, memext_sel_ex, word_size_ex, store_en_ex, ctrl_we_ex, rd_sel_ex, dcd_rd_ex, memext_sel_mem, word_size_mem, store_en_mem, ctrl_we_mem, rd_sel_mem, dcd_rd_mem, ctrl_we_wb, rd_sel_wb, dcd_rd_wb, vl.valids, vl.time_set[1]);*/

      /*$display($time, "pc: %x, pc_dec: %x, ir_dec: %x, pc_ex: %x, target_addr: %x, branch_pc_reg: %x, predicted_pc: %x, flush_dec: %b, flush_ex: %b, brnch_pc: %x, BE_rs: %x, BE_rt: %x, taken_pc: %x, PHT[GHR]: %b, GHR: %b, next_PHT[GHR]: %b, reg 5: %x, valids: %b, ra: %x, rt_sel: %d, rs_sel: %d, after_alu_to_mem: %x, ex_fb: %x, mem_fb: %x, wb_feedback: %x, branch_out_wb: %x, rs: %x, rt: %x\n", pc, pc_dec, instruction_dec, pc_ex, BPreg.target_addr_reg, BPreg.branch_pc_reg, BPreg.predicted_pc, flush_dec, flush_ex, BPreg.branch_pc, bex.rs, bex.rt, taken_pc, BPreg.PHT[0], BPreg.GHR, BPreg.next_PHT[0], rf1.mem[5], vl.valids, rf1.mem[31], rt_sel, rs_sel, after_alu_mem_to_rdmux, ex_feedback, mem_feedback, wb_feedback, branch_out_wb, rs_data, rt_data);*/

	 //$display($time, " pc: %x, inst: %x, rs: %x, rt: %x", pc, inst, rs_data, rt_data);
      if (pc >= 32'h0040002c) begin
	 $display($time, " pc: %x, inst: %x, mem_fb: %x, rt: %x, rt_sel: %d, flush_ex: %x, src2: %x, ts[t0]: %d", pc, inst, mem_feedback, rt_to_src2mux, rt_sel, flush_ex, src2_mux_out, vl.time_set[8]);
	 
      end
   end
   

   
   
   
   // End of automatics

   assign mem_data_in = controller_out;
   assign mem_addr = alu_to_mem[31:2];

   //feedback logic
   feedback_logic fbl(
		      //inputs
		      .mul_en(mul_en_ex),
		      .mul_en_mem(mul_en_mem),
		      .mul_en_wb(mul_en_wb),
		      .branch_en(branch_en_ex),
		      .branch_en_mem(branch_en_mem),
		      .branch_en_wb(branch_en_wb),
		      .loading_mem(loading_mem),
		      .loading_wb(loading_wb),
		      .mul_out(mul__out),
		      .mul_to_mem(mul_to_mem),
		      .after_mul_to_mem(after_mul_mem_to_rdmux),
		      .branch_out(branch_out),
		      .branch_out_mem(branch_out_mem),
		      .branch_out_wb(branch_out_wb),
		      .alu_out(alu__out),
		      .alu_to_mem(alu_to_mem),
		      .after_alu_to_mem(after_alu_mem_to_rdmux),
		      .processed_data(processed_data),
		      .processed_data_wb(procData_to_rdmux),
		      //outputs
		      .ex_feedback(ex_feedback),
		      .mem_feedback(mem_feedback),
		      .wb_feedback(wb_feedback));

   
   //kill timer
   timerr  kt(start_timerr, clk, rst_b, timerr);

   //rt_mux
   mux rt_mux(.a(rt_data),
	      .b(ex_feedback),
	      .c(mem_feedback),
	      .d(wb_feedback),
	      .sel(rt_sel),
	      .out(rt_mux_out));

   //rs_mux
   mux rs_mux(.a(rs_data),
	      .b(ex_feedback),
	      .c(mem_feedback),
	      .d(wb_feedback),
	      .sel(rs_sel),
	      .out(rs_mux_out));

   
   // src2mux
   mux src2_mux(.a(rt_to_src2mux),
		.b(imm_se_to_src2mux),
		.c(imm_e_to_src2mux),
		.d(0),
		.sel(src2_sel_ex),
		.out(src2_mux_out));
   
   //src1mux
   mux src1_mux(.a(rs_to_src1mux),
		.b(0),
		.c(shamt_to_src1mux),
		.d(0),
		.sel(src1_sel_ex),
		.out(src1_mux_out));

   //rdmux
   mux rd_mux(.a(after_alu_mem_to_rdmux),
	      .b(procData_to_rdmux),
	      .c(after_mul_mem_to_rdmux),
	      .d(branch_out_wb),
	      .sel(rd_sel_wb),
	      .out(rd_data));


  /* always @(posedge clk or negedge clk) begin
      $display($time, " clk: %b, store_en: %b, mem_write_en: %b, processed_data: %h, alu__out: %h, src1_mux_out: %h, src2_mux_out: %h, data: %h, data_in: %h, mem_addr: %h", clk, store_en, mem_write_en, processed_data, alu__out, src1_mux_out, src2_mux_out, mem_data_out, mem_data_in, mem_addr);
   end*/
   //process loaded memory
   memory_processor mp1(.addr(alu_to_mem),
			.data(mem_data_out),
			.memext(memext_sel_mem),
			.word_size(word_size_mem),
			.processed_data(processed_data));

   mem_write_controller mdc1(.addr(alu_to_mem),
			     .data_to_write(rt_to_mem),
			     .store_en(store_en_mem),
			     .word_size(word_size_mem),
			     .mem_write_en(mem_write_en),
			     .controller_out(controller_out));
   
   // Generate control signals
   mips_decode Decoder(/*AUTOINST*/
		       // Outputs
		       .ctrl_we		(ctrl_we),
		       .ctrl_Sys	(ctrl_Sys),
		       .ctrl_RI		(ctrl_RI),
		       .alu_sel	(alu__sel[3:0]),
		       .src1_sel(src1_sel),
		       .src2_sel(src2_sel),
		       .rd_sel(rd_sel),
		       .rd_num(dcd_rd),
		       .memext_sel(memext_sel),
		       .word_size(word_size),
		       .store_en(store_en),
		       .mul_en(mul_en),
		       .mul_sel(mul_sel),
		       .start_timerr(start_timerr),
		       .loading(loading),
		       .pc_sel(pc_sel),
		       .branch_sel(branch_sel),
		       .branch_en(branch_en),
		       // Inputs
		       .timerr(timerr),
		       .inst_rd(instruction_dec[15:11]),
		       .dcd_op		(dcd_op[5:0]),
		       .dcd_funct2	(dcd_funct2[5:0]),
		       .rt(rt_data),
		       .rs(rs_data),
		       .rt_num(dcd_rt));
   
   // Register File
   // Instantiate the register file from reg_file.v here.
   // Don't forget to hookup the "halted" signal to trigger the register dump 
   regfile rf1(
	       .rs_data(rs_data),
	       .rt_data(rt_data), 
	       .rs_num(dcd_rs), 
	       .rt_num(dcd_rt),
	       .rd_num(dcd_rd_wb),
	       .rd_data(rd_data),
	       .rd_we(ctrl_we_wb),
	       .clk(clk),
	       .rst_b(rst_b),
	       .halted(halted));
   

   // Execute
   mips_ALU ALU(.alu__out(alu__out), 
                .alu__op1(src1_mux_out),
                .alu__op2(src2_mux_out),
                .alu__sel(alu_sel_ex));

   multiply_coprocessor mcp(.mul__rd_data(mul__out),
			    .clk(clk),
			    .rst_b(rst_b),
			    .mul__opcode(mul_sel_ex),
			    .mul__active(mul_en_ex),
			    .rs_data(src1_mux_out),
			    .rt_data(src2_mux_out));
   
   // Miscellaneous stuff (Exceptions, syscalls, and halt)
   exception_unit EU(.exception_halt(exception_halt), .pc(pc), .rst_b(rst_b),
		     .clk(clk), .load_ex_regs(load_ex_regs),
		     .load_bva(load_bva), .load_bva_sel(load_bva_sel),
		     .cause(cause_code),
		     .IBE(inst_excpt),
		     .DBE(1'b0),
		     .RI(ctrl_RI),
		     .Ov(1'b0),
		     .BP(1'b0),
		     .AdEL_inst(pc[1:0]?1'b1:1'b0),
		     .AdEL_data(1'b0),
		     .AdES(1'b0),
		     .CpU(1'b0));
   
   assign r_v0 = 32'h0a; // Good enough for now. To support syscall for real,
                         // you should read the syscall
                         // argument from $v0 of the register file 

   syscall_unit SU(.syscall_halt(syscall_halt), .pc(pc), .clk(clk), .Sys(ctrl_Sys),
                   .r_v0(r_v0), .rst_b(rst_b));
   assign        internal_halt = exception_halt | syscall_halt;
   register #(1, 0) Halt(halted, internal_halt, clk, 1'b1, rst_b, 1'b0);
   register #(32, 0) EPCReg(epc, pc, clk, load_ex_regs, rst_b, 1'b0);
   register #(32, 0) CauseReg(cause,
                              {25'b0, cause_code, 2'b0}, 
                              clk, load_ex_regs, rst_b, 1'b0);
   register #(32, 0) BadVAddrReg(bad_v_addr, pc, clk, load_bva, rst_b, 1'b0);
   
endmodule // mips_core

module feedback_logic(mul_en, mul_en_mem, mul_en_wb, branch_en, branch_en_mem, branch_en_wb, loading_mem, loading_wb, mul_out, mul_to_mem, after_mul_to_mem, branch_out, branch_out_mem, branch_out_wb, alu_out, alu_to_mem, after_alu_to_mem, processed_data, processed_data_wb,
		      ex_feedback, mem_feedback, wb_feedback);

   input mul_en, mul_en_mem, mul_en_wb, branch_en, branch_en_mem, branch_en_wb, loading_mem, loading_wb;
   input [31:0] mul_out, mul_to_mem, after_mul_to_mem;
   input [31:0] branch_out, branch_out_mem, branch_out_wb;
   input [31:0] alu_out, alu_to_mem, after_alu_to_mem;
   input [31:0] processed_data, processed_data_wb;
   output reg [31:0] ex_feedback, mem_feedback, wb_feedback;
   
   
   always @(*) begin
      if (mul_en) ex_feedback = mul_out;
      else if (branch_en) ex_feedback = branch_out;
      else ex_feedback = alu_out;
   end // always @ begin

   always @(*) begin
      if (loading_mem) mem_feedback = processed_data;
      else if (mul_en_mem) mem_feedback = mul_to_mem;
      else if (branch_en_mem) mem_feedback = branch_out_mem;
      else mem_feedback = alu_to_mem;
   end // always @ begin

   always @(*) begin
      if (loading_wb) wb_feedback = processed_data_wb;
      else if (mul_en_wb) wb_feedback = after_mul_to_mem;
      else if (branch_en_wb) wb_feedback = branch_out_wb;
      else wb_feedback = after_alu_to_mem;
   end // always @ begin
   
endmodule // feedback_logic 

module brnchPredictReg(
			//outputs
		       new_pc,
		       flush_ex,
		       flush_dec,
		       GHR,
		       //inputs
		       taken_pc,
		       pc_ready,
		       current_pc,
		       branch_pc,
		       target_addr,
		       rs_data,
		       offset,
		       pc_sel,
		       stall,
		       clk,
		       rst_b);

   input clk, rst_b, stall;
   input pc_ready;
   input [1:0] pc_sel;
   input       taken_pc;
   output reg [31:0] new_pc;
   output reg [11:0] GHR;
   
   output reg 	     flush_ex, flush_dec;
   input [31:0]      current_pc;
   input [31:0]      offset;
   input [31:0]      branch_pc;
   
   input [31:0]      target_addr, rs_data;

   reg [31:0] 	     next_predicted_pc, predicted_pc;
   reg [31:0] 	     next_branch_pc_reg, branch_pc_reg;
   
   reg 	[31:0]     next_target_addr_reg, target_addr_reg;
   reg [11:0] 	   next_GHR;
   reg [1:0] 	   next_PHT[0:4095], PHT[0:4095];
   reg [12:0] 	   i;
   reg [1:0] 	   next_PHTL[0:1023], PHTL[0:1023];
   reg [9:0] 	   next_LHR[0:15], LHR[0:15];
   reg [31:0] 	   next_pc_table[0:15], pc_table[0:15];
   reg 		   found;
   
   //flush logic
   always @(*) begin
      if (pc_ready) begin
	 if (taken_pc && predicted_pc != target_addr_reg) flush_ex = 1;
	 else if (!taken_pc && predicted_pc == target_addr_reg) flush_ex = 1;
	 else flush_ex = 0;
      end
      else flush_ex = 0;
   end
   
   //logic for setting target address
   always @(*) begin
      case (pc_sel)
	2'd0: next_target_addr_reg = target_addr_reg;
	2'd1: next_target_addr_reg = target_addr;
	2'd2: next_target_addr_reg = rs_data;
	2'd3: next_target_addr_reg = branch_pc + (offset << 2) + 4;
      endcase // case (pc_sel)
   end // always @ begin

   //logic for forming and saving predicted pc as well as the pc of the branch itself
   always @(*) begin
      if (stall) begin
	 flush_dec = 0;
	 next_predicted_pc = predicted_pc;
      end
      else if (pc_sel != 0) begin
	 if (~choice) begin
	    next_branch_pc_reg = branch_pc;
	    flush_dec = 0;
	    case (PHT[GHR])
	      2'd0: next_predicted_pc = current_pc + 4;
	      2'd1: next_predicted_pc = current_pc + 4;
	      2'd2: begin
		 next_predicted_pc = next_target_addr_reg;
		 flush_dec = 1;
	      end
	      2'd3: begin
		 next_predicted_pc = next_target_addr_reg;
		 flush_dec = 1;
	      end
	    endcase // case (PHT[GHR])
	 end // if (~choice)
	 else begin
	    next_branch_pc_reg = branch_pc;
	    flush_dec = 0;
	    case (PHTL[LHR[index]])
	      2'd0: next_predicted_pc = current_pc + 4;
	      2'd1: next_predicted_pc = current_pc + 4;
	      2'd2: begin
		 next_predicted_pc = next_target_addr_reg;
		 flush_dec = 1;
	      end
	      2'd3: begin
		 next_predicted_pc = next_target_addr_reg;
		 flush_dec = 1;
	      end
	    endcase // case (PHTL[LHR[index]])
	 end
      end
      else begin
	 flush_dec = 0;
	 next_branch_pc_reg = branch_pc_reg;
	 next_predicted_pc = predicted_pc;
      end
   end // always @ begin
   
   //logic for pc mux
   always @(*) begin
      if (stall) new_pc = current_pc;
      else if (pc_ready) begin
	 if (taken_pc && predicted_pc == target_addr_reg) new_pc = current_pc + 4;
	 else if (!taken_pc && predicted_pc == target_addr_reg) new_pc = branch_pc_reg + 4;
	 else if (!taken_pc && predicted_pc != target_addr_reg) new_pc = current_pc + 4; 
	 else new_pc = target_addr_reg;
      end
      else if (pc_sel != 0) begin
	 case (PHT[GHR]) 
	    2'd0: new_pc = current_pc + 4;
	    2'd1: new_pc = current_pc + 4;
	    2'd2: new_pc = next_predicted_pc;
	    2'd3: new_pc = next_predicted_pc;
	 endcase // case (PHT[GHR])
      end
      else new_pc = current_pc + 4;
   end

   //logic for GHR and PHT
   always @(*) begin
      if (pc_ready) begin
	 if (taken_pc) begin
	    next_GHR = (GHR << 1) | 1;
	    case (PHT[GHR])
	      2'd0: next_PHT[GHR] = 2'd1;
	      2'd1: next_PHT[GHR] = 2'd2;
	      2'd2: next_PHT[GHR] = 2'd3;
	      2'd3: next_PHT[GHR] = 2'd3;
	    endcase // case (PHT[GHR])
	 end
	 else begin
	    next_GHR = (GHR << 1);
	    case (PHT[GHR])
	      2'd0: next_PHT[GHR] = 2'd0;
	      2'd1: next_PHT[GHR] = 2'd0;
	      2'd2: next_PHT[GHR] = 2'd1;
	      2'd3: next_PHT[GHR] = 2'd2;
	    endcase
	 end
      end
      else begin
	 next_GHR = GHR;
	 next_PHT[GHR] = PHT[GHR];
      end // else: !if(pc_ready)
   end // always @ begin

   //logic for LHR and PHTL
   always @(*) begin
      if (pc_ready && index > 0) begin
	 if (taken_pc) begin
	    next_LHR[index-1] = (LHR[index-1] << 1) | 1;
	    case (PHTL[LHR[index-1]])
	      2'd0: next_PHTL[LHR[index-1]] = 2'd1;
	      2'd1: next_PHTL[LHR[index-1]] = 2'd2;
	      2'd2: next_PHTL[LHR[index-1]] = 2'd3;
	      2'd3: next_PHTL[LHR[index-1]] = 2'd3;
	    endcase // case (PHTL[LHR[index]])
	 end
	 else begin
	    next_LHR[index-1] = (LHR[index-1] << 1);
	    case (PHTL[LHR[index-1]])
	      2'd0: next_PHTL[LHR[index-1]] = 2'd0;
	      2'd1: next_PHTL[LHR[index-1]] = 2'd0;
	      2'd2: next_PHTL[LHR[index-1]] = 2'd1;
	      2'd3: next_PHTL[LHR[index-1]] = 2'd2;
	    endcase // case (PHTL[LHR[index]])
	 end // else: !if(taken_pc)
      end // if (pc_ready)
      else if (pc_ready && index == 0) begin
	 if (taken_pc) begin
	    next_LHR[15] = (LHR[15] << 1) | 1;
	    case (PHTL[LHR[15]])
	      2'd0: next_PHTL[LHR[15]] = 2'd1;
	      2'd1: next_PHTL[LHR[15]] = 2'd2;
	      2'd2: next_PHTL[LHR[15]] = 2'd3;
	      2'd3: next_PHTL[LHR[15]] = 2'd3;
	    endcase // case (PHTL[LHR[index]])
	 end // if (taken_pc)
	 else begin
	    next_LHR[15] = (LHR[15] << 1);
	    case (PHTL[LHR[15]])
	      2'd0: next_PHTL[LHR[15]] = 2'd0;
	      2'd1: next_PHTL[LHR[15]] = 2'd0;
	      2'd2: next_PHTL[LHR[15]] = 2'd1;
	      2'd3: next_PHTL[LHR[15]] = 2'd2;     
	    endcase // case (PHTL[LHR[index]])
	 end // else: !if(taken_pc)
      end  
      else begin
	 next_LHR[index] = LHR[index];
	 next_PHTL[LHR[index]] = PHTL[LHR[index]];
      end
   end

   //index and pc_table logic
   always @(*) begin
      found = 0;
      if (pc_sel != 0) begin
	 for(i=0; i<16; i=i+1) begin
	    if (pc_table[i] == branch_pc) begin
	       if (i < 15) begin
		  next_index = i+1;
	       end
	       else begin
		  next_index = 0;
	       end
	       found = 1;
	    end
	 end
	 
	 if (index < 15 && ~found) begin
	    next_pc_table[index] = branch_pc;
	    next_index = index + 1;
	 end
	 else if (~found) begin
	    next_pc_table[index] = branch_pc;
	    next_index = 0;
	 end
	 else begin
	    next_pc_table[index] = pc_table[index];
	    next_index = index;
	 end
      end // if (pc_sel != 0)
      else begin
	 next_pc_table[index] = pc_table[index];
	 next_index = index;
      end
   end
	 
   always @(posedge clk or negedge rst_b) begin
      if (~rst_b) begin
	 target_addr_reg <= 0;
	 GHR <= 0;
	 predicted_pc <= 0;
	 branch_pc_reg <= 0;
	 index <= 0;
	 for (i=0; i<4096; i=i+1) begin
	    PHT[i] <= 2'd0;
	    if (i < 1024) PHTL[i] <= 2'd0;
	    if (i < 16) begin
	       LHR[i] <= 10'd0;
	       pc_table[i] <= 32'h0;
	 end
      end
      else begin
	 branch_pc_reg <= next_branch_pc_reg;
	 predicted_pc <= next_predicted_pc;
	 target_addr_reg <= next_target_addr_reg;
	 GHR <= next_GHR;
	 index <= next_index;
	 PHT[GHR] <= next_PHT[GHR];
	 PHTL[LHR[index]] <= next_PHTL[LHR[index]];
	 pc_table[index] <= next_pc_table[index];
      end
   end
endmodule

module branchEx(
		//outputs
		branch_out,
		taken_pc,
		pc_ready,
		//inputs
		link_pc,
		rs,
		rt,
		branch_en,
		branch_sel);

   output reg [31:0] branch_out;
   output reg 	     taken_pc;
   output reg 	     pc_ready;
   input 	     branch_en;
   input [3:0] 	     branch_sel;
   input [31:0]      rs, rt, link_pc;
   

   always @(*) begin
      if (branch_en) begin
	 pc_ready = 1;
	 case (branch_sel)
	   `BRNCH_JR:
	     begin
		branch_out = 0;
		taken_pc = 1;
	     end
	   `BRNCH_JALR:
	     begin
		branch_out = link_pc;
		taken_pc = 1;
	     end
	   `BRNCH_BLTZ:
	     begin
		branch_out = 0;
		if (rs >= 32'h80000000) taken_pc = 1;
		else taken_pc = 0;
	     end
	   `BRNCH_BGEZ:
	     begin
		branch_out = 0;
		if (rs < 32'h80000000) taken_pc = 1;
		else taken_pc = 0;
	     end
	   `BRNCH_BLTZAL:
	     begin
		branch_out = link_pc;
		if (rs >= 32'h80000000) taken_pc = 1;
		else taken_pc = 0;
	     end
	   `BRNCH_BGEZAL:
	     begin
		branch_out = link_pc;
		if (rs < 32'h80000000) taken_pc = 1;
		else taken_pc = 0;
	     end
	   `BRNCH_J:
	     begin
		branch_out = 0;
		taken_pc = 1;
	     end
	   `BRNCH_JAL:
	     begin
		branch_out = link_pc;
		taken_pc = 1;
	     end
	   `BRNCH_BEQ:
	     begin
		branch_out = 0;
		if (rt == rs) taken_pc = 1;
		else taken_pc = 0;
	     end
	   `BRNCH_BNE:
	     begin
		branch_out = 0;
		if (rt != rs) taken_pc = 1;
		else taken_pc = 0;
	     end
	   `BRNCH_BLEZ:
	     begin
		branch_out = 0;
		if (rs >= 32'h80000000 || rs == 0) taken_pc = 1;
		else taken_pc = 0;
	     end
	   `BRNCH_BGTZ:
	     begin
		branch_out = 0;
		if (rs < 32'h80000000 && rs != 0) taken_pc = 1;
		else taken_pc = 0;
	     end
	 endcase // case (branch_sel)
      end // if (branch_en)
      else begin
	 pc_ready = 0;
	 taken_pc = 0;
	 branch_out = 0;
      end
   end // always @ begin
endmodule // branchEx

module timerr(start_timerr, clk, rst_b, timerr);
   input start_timerr, clk, rst_b;
   output reg [1:0] timerr;

   always @(posedge clk or negedge rst_b) begin
      if (~rst_b) timerr <= 2;
      else if (start_timerr || timerr < 2) timerr <= timerr - 1;
      else timerr <= 2;
   end
endmodule // timerr

module mem_write_controller(addr, data_to_write, store_en, word_size, mem_write_en, controller_out);
   input [31:0] addr;
   input 	store_en;
   input [1:0]	word_size;
   input [31:0] data_to_write;
   output reg [3:0] mem_write_en;
   output reg [31:0] controller_out;
   reg 	[1:0]	    byte_num;
   
   always @(*) begin
      mem_write_en = 4'b0;
      byte_num = 32'h00000003 & addr;
      controller_out = (data_to_write << byte_num*8); 
      if (store_en) begin
	 case (word_size)
	   `SIZE_BYTE: mem_write_en = (4'b1000 >> byte_num);
	   `SIZE_HALF: mem_write_en = (4'b1100 >> byte_num);
	   `SIZE_WORD: mem_write_en = 4'b1111;
	   default: mem_write_en = 4'b0;
	 endcase // case (word_size)
      end
   end
endmodule // mem_write_controller

module memory_processor(addr, data, word_size, memext, processed_data);
   input memext;
   input [31:0] addr, data;
   input [1:0] 	word_size;
   output reg [31:0] processed_data;
   reg [1:0] 	     byte_num;
   reg [31:0] 	     temp_half, temp_byte;
   
   
   always @(word_size or addr or data or memext) begin
      byte_num = 32'h00000003 & addr;
      temp_byte = (data >> (byte_num*8)) & 32'h000000FF;
      temp_half = (data >> (byte_num*8)) & 32'h0000FFFF;
      case (word_size)
	`SIZE_BYTE: 
	  begin
	     if (memext == `MEMEXT_E) processed_data = temp_byte;
	     else if (temp_byte < 32'h00000080) processed_data = temp_byte;
	     else processed_data = temp_byte | 32'hFFFFFF00;
	  end
	`SIZE_HALF: 
	  begin
	     if (memext == `MEMEXT_E) processed_data = temp_half;
	     else if (temp_half < 32'h00008000) processed_data = temp_half;
	     else processed_data = temp_half | 32'hFFFF0000;
	  end
	`SIZE_WORD: processed_data = data;
	default: processed_data = 0;
      endcase // case (word_size)
   end // always @ begin
endmodule // memory_processor

module valid_logic(rt_sel, rs_sel, stall, loading, rs_num, rt_num, rd_num, clk, rst_b, flush_ex);

   output reg [1:0] rt_sel;
   output reg [1:0] rs_sel;
   output reg 	    stall;
   
   
   reg [31:0] 	    valids;

   input 	    flush_ex;
   
   input 	    loading;
   input [4:0] 	     rs_num;
   input [4:0] 	     rt_num;
   input [4:0] 	     rd_num;
   input 	     clk, rst_b;
   
   reg [2:0] 	     time_set [31:0];
   reg [5:0] 	     i = 0;

   //if we are using a load for the previous instruction and data dependency, stall
   always @(*) begin
      if (loading && (time_set[rd_num] == 3 || time_set[rs_num] == 3 || time_set[rt_num] == 3)) begin
	 stall = 1;
      end
      else begin
	 stall = 0;
      end // else: !if(temp_half < 32'h00008000)
   end // always @ begin
   
   always @(*) begin
      for (i=0; i<32; i=i+1) begin
	 if (time_set[i] != 0) valids[i] <= 0;
	 else valids[i] = 1;
      end
   end
   
   always @(*) begin
      rs_sel = 0;
      rt_sel = 0;
      if (~valids[rs_num]) begin
	 if (time_set[rs_num] == 3) begin
	    rs_sel = 1;
	 end
	 else if (time_set[rs_num] == 2) begin
	    rs_sel = 2;
	 end
	 else if (time_set[rs_num] == 1) begin
	    rs_sel = 3;
	 end
      end
      
      if (~valids[rt_num]) begin
	 if (time_set[rt_num] == 3) begin
	    rt_sel = 1;
	 end
	 else if (time_set[rt_num] == 2) begin
	    rt_sel = 2;
	 end
	 else if (time_set[rt_num] == 1) begin
	    rt_sel = 3;
	 end
      end
   end // always @ begin
   
	 
   always @(posedge clk or negedge rst_b) begin
      if (~rst_b) begin
	 for (i=0; i<32; i=i+1) begin
	    time_set[i] <= 3'h0;
	    valids[i] <= 1'h1;
	 end
      end
      else begin
	 if (rs_num == 0 && rt_num == 0 && rd_num == 0) begin
	 end
	 else if(rd_num != 0 && ~stall && ~flush_ex) begin
	    time_set[rd_num] <= 3;
	 end 
	 for (i=0; i<32; i=i+1) begin
	    if (time_set[i] != 0 && (i != rd_num || flush_ex)) time_set[i] <= time_set[i] - 1;
	 end
      end
   end
endmodule // valid_logic

module mux(a, b, c, d, out, sel);
   
   input [31:0] a, b, c, d;
   input [1:0] 	sel;
   output reg [31:0] out;
   
   always @(*) begin
      case (sel)
	2'b00: out = a;
	2'b01: out = b;
	2'b10: out = c;
	2'b11: out = d;
	default: out = 1'bx;
      endcase // case (sel)
   end // always @ begin
endmodule // mux 

////
//// mips_ALU: Performs all arithmetic and logical operations
////
//// out (output) - Final result
//// in1 (input)  - Operand modified by the operation
//// in2 (input)  - Operand used (in arithmetic ops) to modify in1
//// sel (input)  - Selects which operation is to be performed
////
module mips_ALU(alu__out, alu__op1, alu__op2, alu__sel);
   
   output reg [31:0] alu__out;
   input [31:0]  alu__op1, alu__op2;
   input [3:0] 	 alu__sel;
   
   
   always @(*) begin
      case (alu__sel)
	`ALU_ADD: alu__out = alu__op1 + alu__op2;
	`ALU_SUB: alu__out = alu__op1 - alu__op2;
	`ALU_AND: alu__out = alu__op1 & alu__op2;
	`ALU_NOR: alu__out = ~(alu__op1 | alu__op2);
	`ALU_OR: alu__out = alu__op1 | alu__op2;
	`ALU_XOR: alu__out = alu__op1 ^ alu__op2;
	`ALU_SET:
	  begin
	     if (alu__op1 >= 32'h80000000) begin
		if (alu__op2 < 32'h80000000) alu__out = 1;
		else if (alu__op1 > alu__op2) alu__out = 1;
		else alu__out = 0;
	     end
	     else begin
		if (alu__op2 >= 32'h80000000) alu__out = 0;
		else if (alu__op2 > alu__op1) alu__out = 1;
		else alu__out = 0;
	     end
	  end
	`ALU_SETU:
	  begin
	     if (alu__op1 < alu__op2) alu__out = 1;
	     else alu__out = 32'b0;
	  end
	`ALU_SLL: alu__out = (alu__op2 << alu__op1);
	`ALU_SRL: alu__out = (alu__op2 >> alu__op1);
	`ALU_SRA: 
	  begin
	     if (alu__op2 >= 32'h80000000) alu__out = (alu__op2 >> alu__op1) | (32'hffffffff << (32-alu__op1));
	     else alu__out =(alu__op2 >> alu__op1);
	  end
	`ALU_LU: alu__out = (alu__op2 << 16); 
	`ALU_LS: alu__out = alu__op1 + alu__op2;
	default: alu__out = 32'bx;
      endcase // case (alu_sel)
   end // always @ (*)
endmodule

//module adder(in1, in2, out, sub);
   

//// register: A register which may be reset to an arbirary value
////
//// q      (output) - Current value of register
//// d      (input)  - Next value of register
//// clk    (input)  - Clock (positive edge-sensitive)
//// enable (input)  - Load new value?
//// reset  (input)  - System reset
////
module register(q, d, clk, enable, rst_b, clear);

   parameter
            width = 32,
            reset_value = 0;
   input clear;
   
   output [(width-1):0] q;
   reg [(width-1):0]    q;
   input [(width-1):0]  d;
   input                 clk, enable, rst_b;

   always @(posedge clk or negedge rst_b)
     if (~rst_b | clear)
       q <= reset_value;
     else if (enable)
       q <= d;

endmodule // register

module ctrl_ex_register(q1, d1, q2, d2, q3, d3, q4, d4, q5, d5, q6, d6, q7, d7, clk, enable, rst_b, clear);

   output [3:0] q1;
   output [1:0] q2, q3;
   output 	q4;
   output [2:0] q5;
   output 	q6;
   output [3:0] q7;
   
   reg [3:0] 	q1;
   reg [1:0] 	q2, q3;
   reg 		q4;
   reg [2:0] 	q5;
   reg 		q6;
   reg [3:0] 	q7;
   
   input [3:0] 	d1;
   input [1:0] 	d2, d3;
   input 	d4;
   input [2:0] 	d5;
   input 	d6;
   input [3:0] 	d7;
   
   input 		clk, enable, rst_b, clear;

   always @(posedge clk or negedge rst_b) begin
     if (~rst_b | clear) begin
	q1 <= 0;
	q2 <= 0;
	q3 <= 0;
	q4 <= 0;
	q5 <= 0;
	q6 <= 0;
	q7 <= 0;
     end
     else if (enable) begin
	q1 <= d1;
	q2 <= d2;
	q3 <= d3;
	q4 <= d4;
	q5 <= d5;
	q6 <= d6;
	q7 <= d7;
     end
   end
endmodule // ctrl_register

module ctrl_mem_register(q1, d1, q2, d2, q3, d3, clk, enable, rst_b);

   output q1, q3;
   output [1:0] q2;

   reg 		q1, q3;
   reg [1:0] 	q2;

   input 	d1, d3;
   input [1:0] 	d2;

   input 	clk, enable, rst_b;

   always @(posedge clk or negedge rst_b) begin
      if (~rst_b) begin
	 q1 <= 0;
	 q2 <= 0;
	 q3 <= 0;
      end
      else if (enable) begin
	 q1 <= d1;
	 q2 <= d2;
	 q3 <= d3;
      end
   end // always @ (posedge clk or negedge rst_b)
endmodule // ctrl_mem_register

module ctrl_wb_register(q1, d1, q2, d2, q3, d3, clk, enable, rst_b, flush_ex);

   output q1;
   output [1:0] q2;
   output [4:0] q3;
   

   reg 		q1;
   reg [1:0] 	q2;
   reg [4:0] 	q3;
   
   input 	d1;
   input [1:0] 	d2;
   input [4:0] 	d3;
   input 	flush_ex;

   
   input 	clk, enable, rst_b;

   always @(posedge clk or negedge rst_b) begin
      if (~rst_b | flush_ex) begin
	 q1 <= 0;
	 q2 <= 0;
	 q3 <= 0;
      end
      else if (enable) begin
	 q1 <= d1;
	 q2 <= d2;
	 q3 <= d3;
      end
   end
endmodule // ctrl_wb_register

////
//// add_const: An adder that adds a fixed constant value
////
//// out (output) - adder result
//// in  (input)  - Operand
////
module add_const(out, in);

   parameter add_value = 1;

   output   [31:0] out;
   input    [31:0] in;

   assign   out = in + add_value;

endmodule // adder

// Local Variables:
// verilog-library-directories:("." "../447rtl")
// End:

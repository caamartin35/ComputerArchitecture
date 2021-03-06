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
   wire [31:0] 	 src1_mux_out, src2_mux_out, pc_mux_out;
   wire [1:0] 	 src2_sel;
   wire [1:0] 	 src1_sel;
   wire [1:0] 	 rd_sel;
   wire [1:0] 	 pc_sel;
   wire 	 memext_sel;
   wire [1:0] 	 word_size;
   wire 	 store_en;
   wire [31:0] 	 processed_data;
   wire [31:0] 	 controller_out;
 	 
   
	 
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
   
   // PC Management
   register #(32, text_start) PCReg(pc, pc_mux_out, clk, ~internal_halt, rst_b);
   add_const #(4) NextPCAdder(nextpc, pc);
   assign        inst_addr = pc[31:2];

   // Instruction decoding
   assign        dcd_op = inst[31:26];    // Opcode
   assign        dcd_rs = inst[25:21];    // rs field
   assign        dcd_rt = inst[20:16];    // rt field
   assign        dcd_shamt = inst[10:6];  // Shift amount
   assign        dcd_bczft = inst[16];    // bczt or bczf?
   assign        dcd_funct1 = inst[4:0];  // Coprocessor 0 function field
   assign        dcd_funct2 = inst[5:0];  // funct field; secondary opcode
   assign        dcd_offset = inst[15:0]; // offset field
        // Sign-extended offset for branches
   assign        dcd_se_offset = { {14{dcd_offset[15]}}, dcd_offset, 2'b00 };
        // Sign-extended offset for load/store
   assign        dcd_se_mem_offset = { {16{dcd_offset[15]}}, dcd_offset };
   assign        dcd_imm = inst[15:0];        // immediate field
   assign        dcd_e_imm = { 16'h0, dcd_imm };  // zero-extended immediate
        // Sign-extended immediate
   assign        dcd_se_imm = { {16{dcd_imm[15]}}, dcd_imm };
   assign        dcd_target = inst[25:0];     // target field
   assign        dcd_code = inst[25:6];       // Breakpoint code
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
   
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [3:0]		alu__sel;		// From Decoder of mips_decode.v
   wire			ctrl_RI;		// From Decoder of mips_decode.v
   wire			ctrl_Sys;		// From Decoder of mips_decode.v
   wire			ctrl_we;		// From Decoder of mips_decode.v









   
   
   
   // End of automatics

   assign mem_data_in = controller_out;
   assign mem_addr = alu__out[31:2];
   
   
   // src2mux
   mux src2_mux(.a(rt_data),
		.b(dcd_se_imm),
		.c(dcd_e_imm),
		.d(0),
		.sel(src2_sel),
		.out(src2_mux_out));
   
   //src1mux
   mux src1_mux(.a(rs_data),
		.b(nextpc),
		.c(shamt_extended),
		.d(0),
		.sel(src1_sel),
		.out(src1_mux_out));

   //rdmux
   mux rd_mux(.a(alu__out),
	      .b(processed_data),
	      .c(nextpc),
	      .d(0),
	      .sel(rd_sel),
	      .out(rd_data));

   //pcmux
   mux pc_mux(.a(nextpc),
	      .b(alu__out),
	      .c(rs_data),
	      .d(target_addr),
	      .sel(pc_sel),
	      .out(pc_mux_out));

   always @(posedge clk or negedge clk) begin
      $display($time, " clk: %b, store_en: %b, mem_write_en: %b, processed_data: %h, alu__out: %h, src1_mux_out: %h, src2_mux_out: %h, data: %h, data_in: %h, mem_addr: %h", clk, store_en, mem_write_en, processed_data, alu__out, src1_mux_out, src2_mux_out, mem_data_out, mem_data_in, mem_addr);
   end
   //process loaded memory
   memory_processor mp1(.addr(alu__out),
			.data(mem_data_out),
			.memext(memext_sel),
			.word_size(word_size),
			.processed_data(processed_data));

   mem_write_controller mdc1(.addr(alu__out),
			     .data_to_write(rt_data),
			     .store_en(store_en),
			     .word_size(word_size),
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
		       .pc_sel(pc_sel),
		       .rd_sel(rd_sel),
		       .rd_num(dcd_rd),
		       .memext_sel(memext_sel),
		       .word_size(word_size),
		       .store_en(store_en),
		       // Inputs
		       .inst_rd(inst[15:11]),
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
	       .rd_num(dcd_rd),
	       .rd_data(rd_data),
	       .rd_we(ctrl_we),
	       .clk(clk),
	       .rst_b(rst_b),
	       .halted(halted));
   

   // Execute
   mips_ALU ALU(.alu__out(alu__out), 
                .alu__op1(src1_mux_out),
                .alu__op2(src2_mux_out),
                .alu__sel(alu__sel));
   
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
   register #(1, 0) Halt(halted, internal_halt, clk, 1'b1, rst_b);
   register #(32, 0) EPCReg(epc, pc, clk, load_ex_regs, rst_b);
   register #(32, 0) CauseReg(cause,
                              {25'b0, cause_code, 2'b0}, 
                              clk, load_ex_regs, rst_b);
   register #(32, 0) BadVAddrReg(bad_v_addr, pc, clk, load_bva, rst_b);
   
endmodule // mips_core

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
	`ALU_BRANCH: alu__out = alu__op1 + (alu__op2 << 2);
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
module register(q, d, clk, enable, rst_b);

   parameter
            width = 32,
            reset_value = 0;

   output [(width-1):0] q;
   reg [(width-1):0]    q;
   input [(width-1):0]  d;
   input                 clk, enable, rst_b;

   always @(posedge clk or negedge rst_b)
     if (~rst_b)
       q <= reset_value;
     else if (enable)
       q <= d;

endmodule // register

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

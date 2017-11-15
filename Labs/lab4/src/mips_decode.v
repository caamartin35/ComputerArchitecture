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

// Include the MIPS constants
`include "mips_defines.vh"
`include "internal_defines.vh"

////
//// mips_decode: Decode MIPS instructions
////
//// op      (input)  - Instruction opcode
//// funct2  (input)  - Instruction minor opcode
//// rt      (input)  - Instruction minor opcode
//// alu_sel (output) - Selects the ALU function
//// we      (output) - Write to the register file
//// Sys     (output) - System call exception
//// RI      (output) - Reserved instruction exception
////
module mips_decode(/*AUTOARG*/
   // Outputs
   ctrl_we, ctrl_Sys, ctrl_RI, alu_sel, src1_sel, src2_sel,  rd_sel, rd_num, memext_sel, word_size, store_en, mul_sel, mul_en, start_timerr, loading, pc_sel, branch_sel, branch_en,
   // Inputs
   dcd_op, rt, rs, dcd_funct2, inst_rd, rt_num, timerr
   );

   input [4:0] inst_rd, rt_num;
   input       [5:0] dcd_op, dcd_funct2;
   output reg        ctrl_we, ctrl_Sys, ctrl_RI, memext_sel;
   output reg  [3:0] alu_sel;
   output reg [1:0]  src1_sel, src2_sel, rd_sel, pc_sel;
   output reg [4:0]  rd_num;
   output reg [1:0]  word_size;
   output reg 	     store_en;
   output reg 	     loading;
   
   input [31:0]      rt, rs;

   input [1:0] 	     timerr;
   output reg 	     start_timerr;
   
   output reg [2:0]  mul_sel;
   output reg 	     mul_en;
   output reg [3:0]  branch_sel;
   output reg 	     branch_en;
   
   
   always @(*) begin
      rd_sel = 2'bx;
      src2_sel = 3'bx;
      alu_sel = 4'hx;
      ctrl_we = 1'bx;
      ctrl_Sys = 1'b0;
      ctrl_RI = 1'b0;
      rd_num = 5'bx;
      src1_sel = 2'bx;
      memext_sel = 1'bx;
      store_en = 1'b0;
      word_size = 2'bx;
      mul_en = 1'b0;
      mul_sel = 3'bx;
      loading = 1'b0;
      pc_sel = `PC_INC;
      branch_sel = 4'bx;
      branch_en = 1'b0;
      
      
      if (timerr == 0) ctrl_Sys = 1;
      
      case(dcd_op)
	`OP_OTHER0:
	  begin
	     case(dcd_funct2)
	       `OP0_SLL: 
		 begin
		    src1_sel = `SRC1_SA;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SLL;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end
	       `OP0_SRL:
		 begin
		    src1_sel = `SRC1_SA;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SRL;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end // case: `OP0_SRL
	       `OP0_SRA:
		 begin
		    src1_sel = `SRC1_SA;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SRA;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end // case: `OP0_SRA
	       `OP0_SLLV: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SLL;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end // case: `OP0_SLLV
	       `OP0_SRLV: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SRL;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end
	       `OP0_SRAV: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SRA;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end
	       `OP0_ADD: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_ADD;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end
	       `OP0_ADDU: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_ADD;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end
	       `OP0_SUB: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SUB;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end
	       `OP0_SUBU:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SUB;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end
	       `OP0_AND:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_AND;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end
	       `OP0_OR: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_OR;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end
	       `OP0_XOR:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_XOR;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end
	       `OP0_NOR: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_NOR;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end
	       `OP0_SLT: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SET;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end
	       `OP0_SLTU:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SETU;
		    ctrl_we = `REG_WRITE;
		    rd_num = inst_rd;
		 end
	       `OP0_MFHI:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_MUL;
		    ctrl_we = `REG_WRITE;
		    mul_en = 1;
		    mul_sel = `MUL_MFHI;
		    rd_num = inst_rd;
		 end
	       `OP0_MTHI:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_MUL;
		    ctrl_we = `REG_READ;
		    mul_en = 1;
		    mul_sel = `MUL_MTHI;
		    rd_num = 0;
		 end
	       `OP0_MFLO:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_MUL;
		    ctrl_we = `REG_WRITE;
		    mul_en = 1;
		    mul_sel = `MUL_MFLO;
		    rd_num = inst_rd;
		 end
	       `OP0_MTLO:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_MUL;
		    ctrl_we = `REG_READ;
		    mul_en = 1;
		    mul_sel = `MUL_MTLO;
		    rd_num = inst_rd;
		 end
	       `OP0_MULT:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_MUL;
		    ctrl_we = `REG_READ;
		    mul_en = 1;
		    mul_sel = `MUL_MULT;
		    rd_num = 0;
		 end
	       `OP0_MULTU:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_MUL;
		    ctrl_we = `REG_READ;
		    mul_en = 1;
		    mul_sel = `MUL_MULTU;
		    rd_num = 0;
		 end
	       `OP0_JR:
		 begin
		    branch_en = 1;
		    branch_sel = `BRNCH_JR;
		    ctrl_we = `REG_READ;
		    pc_sel = `PC_RS;
		    rd_num = 0;
		 end
	       `OP0_JALR:
		 begin
		    branch_en = 1;
		    branch_sel = `BRNCH_JALR;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_RS;
		    rd_sel = `RD_BRNCH;
		    if (inst_rd == 0) rd_num = 31;
		    else rd_num = inst_rd;
		 end
	       `OP0_SYSCALL:
		 begin
		    start_timerr = 1;
		 end
	       default: ctrl_RI = 1'b1;
	     endcase // case (dcd_funct2)
	  end // case: `OP_OTHER0
	`OP_OTHER1:
	  begin
	     case(rt_num)
	       `OP1_BLTZ:
		 begin
		    branch_en = 1;
		    branch_sel = `BRNCH_BLTZ;
		    ctrl_we = `REG_READ;
		    pc_sel = `PC_OFFSET;
		    rd_num = 0; 
		 end
	       `OP1_BGEZ:
		 begin
		    branch_en = 1;
		    branch_sel = `BRNCH_BGEZ;
		    ctrl_we = `REG_READ;
		    pc_sel = `PC_OFFSET;
		    rd_num = 0;
		 end
	       `OP1_BLTZAL:
		 begin
		    branch_en = 1;
		    branch_sel = `BRNCH_BLTZAL;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_OFFSET;
		    rd_sel = `RD_BRNCH;
		    rd_num = 31;
		 end
	       `OP1_BGEZAL:
		 begin
		    branch_en = 1;
		    branch_sel = `BRNCH_BGEZAL;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_OFFSET;
		    rd_sel = `RD_BRNCH;
		    rd_num = 31;
		 end
	       default: ctrl_RI = 1'b1;
	     endcase
	  end
	`OP_J:
	  begin
	     branch_en = 1;
	     branch_sel = `BRNCH_J;
	     ctrl_we = `REG_READ;
	     pc_sel = `PC_TARGET;
	     rd_num = 0;
	  end
	`OP_JAL:
	  begin
	     branch_en = 1;
	     branch_sel = `BRNCH_JAL;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_TARGET;
	     rd_sel = `RD_BRNCH;
	     rd_num = 31;
	  end
	`OP_BEQ:
	  begin
	     branch_en = 1;
	     branch_sel = `BRNCH_BEQ;
	     ctrl_we = `REG_READ;
	     pc_sel = `PC_OFFSET;
	     rd_num = 0;
	  end
	`OP_BNE:
	  begin
	     branch_en = 1;
	     branch_sel = `BRNCH_BNE;
	     ctrl_we = `REG_READ;
	     pc_sel = `PC_OFFSET;
	     rd_num = 0;
	  end
	`OP_BLEZ:
	  begin
	     branch_en = 1;
	     branch_sel = `BRNCH_BLEZ;
	     ctrl_we = `REG_READ;
	     pc_sel = `PC_OFFSET;
	     rd_num = 0;
	  end
	`OP_BGTZ:
	  begin
	     branch_en = 1;
	     branch_sel = `BRNCH_BGTZ;
	     ctrl_we = `REG_READ;
	     pc_sel = `PC_OFFSET;
	     rd_num = 0;
	  end
	`OP_ADDI: 
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_ADD;
	     ctrl_we = `REG_WRITE;
	     rd_num = rt_num;
	  end
	`OP_SLTI: 
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_SET;
	     ctrl_we = `REG_WRITE;
	     rd_num = rt_num;
	  end
	`OP_SLTIU: 
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_SETU;
	     ctrl_we = `REG_WRITE;
	     rd_num = rt_num;
	  end
	`OP_ANDI: 
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_E_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_AND;
	     ctrl_we = `REG_WRITE;
	     rd_num = rt_num;
	  end
	`OP_ORI: 
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_E_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_OR;
	     ctrl_we = `REG_WRITE;
	     rd_num = rt_num;
	  end
	`OP_XORI:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_E_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_XOR;
	     ctrl_we = `REG_WRITE;
	     rd_num = rt_num;
	  end
	`OP_LUI:
	  begin
	     src1_sel = 2'bx;
	     src2_sel = `SRC2_E_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_LU;
	     ctrl_we = `REG_WRITE;
	     rd_num = rt_num;
	  end
	`OP_LBU:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_MEM;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_WRITE;
	     memext_sel = `MEMEXT_E;
	     word_size = `SIZE_BYTE;
	     rd_num = rt_num;
	     loading = 1;
	  end
	`OP_LHU: 
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_MEM;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_WRITE;
	     memext_sel = `MEMEXT_E;
	     word_size = `SIZE_HALF;
	     rd_num = rt_num;
	     loading = 1;
	  end
	`OP_SB:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = 2'bx;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_READ;
	     word_size = `SIZE_BYTE;
	     rd_num = 0;
	     store_en = 1;
	  end
	`OP_SH:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = 2'bx;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_READ;
	     word_size = `SIZE_HALF;
	     rd_num = 0;
	     store_en = 1;
	  end
	`OP_LB:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_MEM;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_WRITE;
	     memext_sel = `MEMEXT_SE;
	     word_size = `SIZE_BYTE;
	     rd_num = rt_num;
	     loading = 1;
	  end
	`OP_LH:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_MEM;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_WRITE;
	     memext_sel = `MEMEXT_SE;
	     word_size = `SIZE_HALF;
	     rd_num = rt_num;
	     loading = 1;
	  end
	`OP_LW:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_MEM;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_WRITE;
	     memext_sel = `MEMEXT_SE;
	     word_size = `SIZE_WORD;
	     rd_num = rt_num;
	     loading = 1;
	  end
	`OP_SW:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = 2'bx;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_READ;
	     word_size = `SIZE_WORD;
	     rd_num = 0;
	     store_en = 1;
	  end
	`OP_ADDIU:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_ADD;
	     ctrl_we = `REG_WRITE;
	     rd_num = rt_num;
	  end
	
	default: 
	  begin
	     ctrl_RI = 1'b1;
	  end
      endcase // case(op)
   end
endmodule // executer       
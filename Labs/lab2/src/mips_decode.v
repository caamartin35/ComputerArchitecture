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
   ctrl_we, ctrl_Sys, ctrl_RI, alu_sel, src1_sel, src2_sel, pc_sel, rd_sel, rd_num, memext_sel, word_size, store_en,
   // Inputs
   dcd_op, rt, rs, dcd_funct2, inst_rd, rt_num
   );

   input [4:0] inst_rd, rt_num;
   input       [5:0] dcd_op, dcd_funct2;
   output reg        ctrl_we, ctrl_Sys, ctrl_RI, memext_sel;
   output reg  [3:0] alu_sel;
   output reg [1:0]  src1_sel, src2_sel, pc_sel, rd_sel;
   output reg [4:0]  rd_num;
   output reg [1:0]  word_size;
   output reg 	     store_en;
   input [31:0]      rt, rs;
   
   
   always @(*) begin
      rd_sel = 2'bx;
      pc_sel = 2'bx;
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
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP0_SRL:
		 begin
		    src1_sel = `SRC1_SA;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SRL;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end // case: `OP0_SRL
	       `OP0_SRA:
		 begin
		    src1_sel = `SRC1_SA;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SRA;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end // case: `OP0_SRA
	       `OP0_SLLV: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SLL;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end // case: `OP0_SLLV
	       `OP0_SRLV: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SRL;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP0_SRAV: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SRA;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP0_JR:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_0;
		    rd_sel = 2'bx;
		    alu_sel = `ALU_ADD;
		    ctrl_we = `REG_READ;
		    pc_sel = `PC_ALU;
		    rd_num = inst_rd;
		 end
	       `OP0_JALR:
		 begin
		    src1_sel = `SRC1_PCNEXT;
		    src2_sel = `SRC2_0;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_ADD;
		    ctrl_we = `REG_READ;
		    pc_sel = `PC_RS;
		    if (inst_rd == 0) rd_num = 31;
		    else rd_num = inst_rd;
		 end
	       `OP0_ADD: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_ADD;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP0_ADDU: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_ADD;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP0_SUB: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SUB;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP0_SUBU:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SUB;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP0_AND:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_AND;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP0_OR: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_OR;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP0_XOR:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_XOR;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP0_NOR: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_NOR;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP0_SLT: 
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SET;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP0_SLTU:
		 begin
		    src1_sel = `SRC1_RS;
		    src2_sel = `SRC2_RT;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_SETU;
		    ctrl_we = `REG_WRITE;
		    pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       default: ctrl_RI = 1'b1;
	     endcase // case (dcd_funct2)
	  end // case: `OP_OTHER0
	`OP_OTHER1:
	  begin
	     case (rt_num)
	       `OP1_BLTZ:
		 begin
		    src1_sel = `SRC1_PCNEXT;
		    src2_sel = `SRC2_SE_IMM;
		    rd_sel = 1'bx;
		    alu_sel = `ALU_BRANCH;
		    ctrl_we = `REG_READ;
		    if (rs >= 32'h80000000) pc_sel = `PC_ALU;
		    else pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP1_BGEZ:  
		 begin
		    src1_sel = `SRC1_PCNEXT;
		    src2_sel = `SRC2_SE_IMM;
		    rd_sel = `RD_ALU;
		    alu_sel = `ALU_BRANCH;
		    ctrl_we = `REG_READ;
		    if (rs < 32'h80000000) pc_sel = `PC_ALU;
		    else pc_sel = `PC_INC;
		    rd_num = inst_rd;
		 end
	       `OP1_BLTZAL: 
		 begin
		    src1_sel = `SRC1_PCNEXT;
		    src2_sel = `SRC2_SE_IMM;
		    rd_sel = `RD_PCNEXT;
		    alu_sel = `ALU_BRANCH;
		    ctrl_we = `REG_READ;
		    if (rs >= 32'h80000000) pc_sel = `PC_ALU;
		    else pc_sel = `PC_INC;
		    rd_num = 31;
		 end
	       `OP1_BGEZAL:
		 begin
		    src1_sel = `SRC1_PCNEXT;
		    src2_sel = `SRC2_SE_IMM;
		    rd_sel = `RD_PCNEXT;
		    alu_sel = `ALU_BRANCH;
		    ctrl_we = `REG_READ;
		    if (rs < 32'h80000000) pc_sel = `PC_ALU;
		    else pc_sel = `PC_INC;
		    rd_num = 31;
		 end
	       default: ctrl_RI = 1'b1;
	     endcase // case (rt)
	  end // case:
	`OP_J: 
	  begin
	     src1_sel = 3'bx;
	     src2_sel = 3'bx;
	     rd_sel = 1'bx;
	     alu_sel = 4'bx;
	     ctrl_we = `REG_READ;
	     pc_sel = `PC_TARGET;
	     rd_num = inst_rd;
	  end
	`OP_JAL:
	  begin
	     src1_sel = `SRC1_PCNEXT;
	     src2_sel = `SRC2_0;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_ADD;
	     ctrl_we = `REG_READ;
	     pc_sel = `PC_TARGET;
	     rd_num = 31;
	  end // case: `OP_JAL
	`OP_BEQ:
	  begin
	     src1_sel = `SRC1_PCNEXT;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = 1'bx;
	     alu_sel = `ALU_BRANCH;
	     ctrl_we = `REG_READ;
	     if (rt == rs) pc_sel = `PC_ALU;
	     else pc_sel = `PC_INC;
	     rd_num = inst_rd;
	  end
	`OP_BNE:
	  begin
	     src1_sel = `SRC1_PCNEXT;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = 1'bx;
	     alu_sel = `ALU_BRANCH;
	     ctrl_we = `REG_READ;
	     if (rt != rs) pc_sel = `PC_ALU;
	     else pc_sel = `PC_INC;
	     rd_num = inst_rd;
	  end
	`OP_BLEZ:
	  begin
	     src1_sel = `SRC1_PCNEXT;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = 1'bx;
	     alu_sel = `ALU_BRANCH;
	     ctrl_we = `REG_READ;
	     if (rs >= 32'h80000000 || rs == 0) pc_sel = `PC_ALU;
	     else pc_sel = `PC_INC;
	     rd_num = inst_rd;
	  end
	`OP_BGTZ:
	  begin
	     src1_sel = `SRC1_PCNEXT;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = 1'bx;
	     alu_sel = `ALU_BRANCH;
	     ctrl_we = `REG_READ;
	     if (rs < 32'h80000000 && rs != 0) pc_sel = `PC_ALU;
	     else pc_sel = `PC_INC;
	     rd_num = inst_rd;
	  end
	`OP_ADDI: 
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_ADD;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_INC;
	     rd_num = rt_num;
	  end
	`OP_SLTI: 
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_SET;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_INC;
	     rd_num = rt_num;
	  end
	`OP_SLTIU: 
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_SETU;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_INC;
	     rd_num = rt_num;
	  end
	`OP_ANDI: 
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_E_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_AND;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_INC;
	     rd_num = rt_num;
	  end
	`OP_ORI: 
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_E_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_OR;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_INC;
	     rd_num = rt_num;
	  end
	`OP_XORI:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_E_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_XOR;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_INC;
	     rd_num = rt_num;
	  end
	`OP_LUI:
	  begin
	     src1_sel = 2'bx;
	     src2_sel = `SRC2_E_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_LU;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_INC;
	     rd_num = rt_num;
	  end
	`OP_LBU:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_MEM;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_INC;
	     memext_sel = `MEMEXT_E;
	     word_size = `SIZE_BYTE;
	     rd_num = rt_num;
	  end
	`OP_LHU: 
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_MEM;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_INC;
	     memext_sel = `MEMEXT_E;
	     word_size = `SIZE_HALF;
	     rd_num = rt_num;
	  end
	`OP_SB:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = 2'bx;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_READ;
	     pc_sel = `PC_INC;
	     word_size = `SIZE_BYTE;
	     rd_num = inst_rd;
	     store_en = 1;
	  end
	`OP_SH:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = 2'bx;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_READ;
	     pc_sel = `PC_INC;
	     word_size = `SIZE_HALF;
	     rd_num = inst_rd;
	     store_en = 1;
	  end
	`OP_LB:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_MEM;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_INC;
	     memext_sel = `MEMEXT_SE;
	     word_size = `SIZE_BYTE;
	     rd_num = rt_num;
	  end
	`OP_LH:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_MEM;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_INC;
	     memext_sel = `MEMEXT_SE;
	     word_size = `SIZE_HALF;
	     rd_num = rt_num;
	  end
	`OP_LW:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_MEM;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_INC;
	     memext_sel = `MEMEXT_SE;
	     word_size = `SIZE_WORD;
	     rd_num = rt_num;
	  end
	`OP_SW:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = 2'bx;
	     alu_sel = `ALU_LS;
	     ctrl_we = `REG_READ;
	     pc_sel = `PC_INC;
	     word_size = `SIZE_WORD;
	     rd_num = rt_num;
	     store_en = 1;
	  end
	`OP_ADDIU:
	  begin
	     src1_sel = `SRC1_RS;
	     src2_sel = `SRC2_SE_IMM;
	     rd_sel = `RD_ALU;
	     alu_sel = `ALU_ADD;
	     ctrl_we = `REG_WRITE;
	     pc_sel = `PC_INC;
	     rd_num = rt_num;
	  end
	default: 
	  begin
	     ctrl_RI = 1'b1;
	     pc_sel = `PC_INC;
	  end
      endcase // case(op)
   end
endmodule // executer       
/*
 * ECE 18-447, Spring 2013
 *
 * MIPS core->pipeline timing simulator
 *
 * Chris Fallin, 2012
 */

#include "pipe.h"
#include "shell.h"
#include "mips.h"
#include "cache.h"
#include "l2.h"
#include "predictor.h"
#include "mem_ctrl.h"
#include "processor.h"
#include "core.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>

#define DEBUG

/* debug */
void print_op(Pipe_Op *op)
{
    if (op)
        printf("OP (PC=%08x inst=%08x) src1=R%d (%08x) src2=R%d (%08x) dst=R%d valid %d (%08x) br=%d taken=%d dest=%08x mem=%d addr=%08x\n",
                op->pc, op->instruction, op->reg_src1, op->reg_src1_value, op->reg_src2, op->reg_src2_value, op->reg_dst, op->reg_dst_value_ready,
                op->reg_dst_value, op->is_branch, op->branch_taken, op->branch_dest, op->is_mem, op->mem_addr);
    else
        printf("(null)\n");
}

void init_pipe()
{
    memset(&core->pipe, 0, sizeof(Pipe_State));
    core->pipe.PC = 0x00400000;
}

void pipe_cycle()
{
#ifdef DEBUG

  printf("\n\n----\n\ncore->pipeLINE (CPU %d Cycle %d):\n", core->core_num, stat_cycles);
    printf("FETCH: PC=%x\n", core->pipe.PC);
    printf("DCODE: "); print_op(core->pipe.decode_op);
    printf("EXEC : "); print_op(core->pipe.execute_op);
    printf("MEM  : "); print_op(core->pipe.mem_op);
    printf("WB   : "); print_op(core->pipe.wb_op);
    printf("\n");

    printf("core->pipe: inst_stall: %d\n", core->pipe.inst_stall);
    printf("core->pipe: data_stall: %d\n", core->pipe.data_stall);
#endif
    printf("core->pipe: BEFORE CYCLE\n");
    pipe_stage_wb();
    pipe_stage_mem();
    pipe_stage_execute();
    pipe_stage_decode();
    pipe_stage_fetch();

    printf("core->pipe: AFTER CYCLE\n");
    printf("core->pipe: inst_stall: %d\n", core->pipe.inst_stall);
    printf("core->pipe: data_stall: %d\n", core->pipe.data_stall);
    printf("core->pipe: TIME: %d\n", processor.time);

    //increment time
    processor.time++;
    
    //dram handling requests
    Request* request;
    if ((request = schedule_request()) != NULL){
      printf("core->pipe: Controller Scheduled a request: Bank=%d, Row=%d, Time=%d, Source=%d\n", request->bank, request->row, request->time, request->source);
      set_channel_vals(request);
    }
    shift_channel_vals();
    
    /* handle branch recoveries */
    if (core->pipe.branch_recover) {
#ifdef DEBUG
        printf("branch recovery: new dest %08x flush %d stages\n", core->pipe.branch_dest, core->pipe.branch_flush);
#endif

        core->pipe.PC = core->pipe.branch_dest;

        if (core->pipe.branch_flush >= 2) {
            if (core->pipe.decode_op) free(core->pipe.decode_op);
            core->pipe.decode_op = NULL;
        }

        if (core->pipe.branch_flush >= 3) {
            if (core->pipe.execute_op) free(core->pipe.execute_op);
            core->pipe.execute_op = NULL;
        }

        if (core->pipe.branch_flush >= 4) {
            if (core->pipe.mem_op) free(core->pipe.mem_op);
            core->pipe.mem_op = NULL;
        }

        if (core->pipe.branch_flush >= 5) {
            if (core->pipe.wb_op) free(core->pipe.wb_op);
            core->pipe.wb_op = NULL;
        }

        core->pipe.branch_recover = 0;
        core->pipe.branch_dest = 0;
        core->pipe.branch_flush = 0;
        stat_squash++;
    }
}

void pipe_recover(int flush, uint32_t dest)
{
    /* if there is already a recovery scheduled, it must have come from a later
     * stage (which executes older instructions), hence that recovery overrides
     * our recovery. Simply return in this case. */
    if (core->pipe.branch_recover) return;

    /* schedule the recovery. This will be done once all core->pipeline stages simulate the current cycle. */
    core->pipe.branch_recover = 1;
    core->pipe.branch_flush = flush;
    core->pipe.branch_dest = dest;
}

void pipe_stage_wb()
{
    /* if there is no instruction in this core->pipeline stage, we are done */
    if (!core->pipe.wb_op)
        return;

    /* grab the op out of our input slot */
    Pipe_Op *op = core->pipe.wb_op;
    core->pipe.wb_op = NULL;

    /* if this instruction writes a register, do so now */
    if (op->reg_dst != -1 && op->reg_dst != 0) {
        core->pipe.REGS[op->reg_dst] = op->reg_dst_value;
#ifdef DEBUG
        printf("R%d = %08x\n", op->reg_dst, op->reg_dst_value);
#endif
    }

    /* if this was a syscall, perform action */
    if (op->opcode == OP_SPECIAL && op->subop == SUBOP_SYSCALL) {
        switch (op->reg_src1_value){
            case 0x1:
                spawn(1, op->pc);
                break;
            case 0x2:
                spawn(2, op->pc);
                break;
            case 0x3:
                spawn(3, op->pc);
                break;
            case 0xA:
                core->pipe.PC = op->pc; /* fetch will do pc += 4, then we stop with correct PC */
                core->pipe.inst_stall = 0;
                stat_inst_fetch--;
                core->RUN_BIT = 0;
                break;
            case 0xB:
                printf("OUT (CPU %d): %x\n", core->core_num, op->reg_src2_value);
                break;
        }
    }

    /* free the op */
    free(op);

    stat_inst_retire++;
}

void pipe_stage_mem()
{

    /* if there is no instruction in this core->pipeline stage, we are done */
    if (!core->pipe.mem_op)
        return;

    /* grab the op out of our input slot */
    Pipe_Op *op = core->pipe.mem_op;

    //////////////                                                                                                                                                
    //DATA CACHE//                                                                                                                                                 
    //////////////                                                                                                                                                


    if (op->is_mem){
        if (!core->pipe.data_stall){
            if (!data_check(op->mem_addr) || core->l1_data_cache.miss.miss_cycles > 0)
                core->pipe.data_stall = 1;
        }

	if (core->l1_data_cache.miss.zero == 1){
	  core->l1_data_cache.miss.zero = 0;
	  core->pipe.data_stall = 0;
	}

        else{
            if (l2_data_hit_handler(op->mem_addr)){
                core->pipe.data_stall = 0;
		core->transfer = (l2_probe(op->mem_addr))->data;
		data_load(op->mem_addr, EXCLUSIVE, core->transfer);
            }      
        }
    }

    if (core->pipe.data_stall > 0)
        return;

    //////////////////                                                                                                                                            
    //END DATA CACHE// 
    //////////////////

    if (op->opcode == OP_SPECIAL && op->subop == SUBOP_SYSCALL)
        core->pipe.syscall_stall = 1;

    uint32_t val = 0;
    if (op->is_mem)
        val = mem_read_32(op->mem_addr & ~3);
  

      switch (op->opcode) {
      case OP_LW:
      case OP_LH:
      case OP_LHU:
      case OP_LB:
      case OP_LBU:
        {
          /* extract needed value */
          op->reg_dst_value_ready = 1;
          if (op->opcode == OP_LW) {
    	op->reg_dst_value = val;
          }
          else if (op->opcode == OP_LH || op->opcode == OP_LHU) {
    	if (op->mem_addr & 2)
    	  val = (val >> 16) & 0xFFFF;
    	else
    	  val = val & 0xFFFF;
    	
    	if (op->opcode == OP_LH)
    	  val |= (val & 0x8000) ? 0xFFFF8000 : 0;
    	
    	op->reg_dst_value = val;
          }
          else if (op->opcode == OP_LB || op->opcode == OP_LBU) {
    	switch (op->mem_addr & 3) {
    	case 0:
    	  val = val & 0xFF;
    	  break;
    	case 1:
    	  val = (val >> 8) & 0xFF;
    	  break;
    	case 2:
    	  val = (val >> 16) & 0xFF;
    	  break;
    	case 3:
    	  val = (val >> 24) & 0xFF;
    	  break;
    	}
    	
    	if (op->opcode == OP_LB)
    	  val |= (val & 0x80) ? 0xFFFFFF80 : 0;
    	
    	op->reg_dst_value = val;
          }
        }
        break;
        
      case OP_SB:
        switch (op->mem_addr & 3) {
        case 0: val = (val & 0xFFFFFF00) | ((op->mem_value & 0xFF) << 0); break;
        case 1: val = (val & 0xFFFF00FF) | ((op->mem_value & 0xFF) << 8); break;
        case 2: val = (val & 0xFF00FFFF) | ((op->mem_value & 0xFF) << 16); break;
        case 3: val = (val & 0x00FFFFFF) | ((op->mem_value & 0xFF) << 24); break;
        }
        
	core->transfer[0] = val;
        data_load(op->mem_addr & ~3, MODIFIED, core->transfer);
        break;
        
      case OP_SH:
    #ifdef DEBUG
        printf("SH: addr %08x val %04x old word %08x\n", op->mem_addr, op->mem_value & 0xFFFF, val);
    #endif
        if (op->mem_addr & 2)
          val = (val & 0x0000FFFF) | (op->mem_value) << 16;
        else
          val = (val & 0xFFFF0000) | (op->mem_value & 0xFFFF);
    #ifdef DEBUG
        printf("new word %08x\n", val);
    #endif
        
	core->transfer[0] = val;
        data_load(op->mem_addr & ~3, MODIFIED, core->transfer);
        break;
        
      case OP_SW:
        val = op->mem_value;
	core->transfer[0] = val;
        data_load(op->mem_addr & ~3, MODIFIED, core->transfer);
        break;
      }
      
      /* clear stage input and transfer to next stage */
      core->pipe.mem_op = NULL;
      core->pipe.wb_op = op;
}

void pipe_stage_execute()
{

    /* if a multiply/divide is in progress, decrement cycles until value is ready */
    if (core->pipe.multiplier_stall > 0)
        core->pipe.multiplier_stall--;

    /* if downstream stall, return (and leave any input we had) */
    if (core->pipe.mem_op != NULL)
        return;

    /* if no op to execute, return */
    if (core->pipe.execute_op == NULL)
        return;

    /* grab op and read sources */
    Pipe_Op *op = core->pipe.execute_op;
    struct BTBentry newBTB;

    /* read register values, and check for bypass; stall if necessary */
    int stall = 0;
    if (op->reg_src1 != -1) {
        if (op->reg_src1 == 0)
            op->reg_src1_value = 0;
        else if (core->pipe.mem_op && core->pipe.mem_op->reg_dst == op->reg_src1) {
            if (!core->pipe.mem_op->reg_dst_value_ready)
                stall = 1;
            else
                op->reg_src1_value = core->pipe.mem_op->reg_dst_value;
        }
        else if (core->pipe.wb_op && core->pipe.wb_op->reg_dst == op->reg_src1) {
            op->reg_src1_value = core->pipe.wb_op->reg_dst_value;
        }
        else
            op->reg_src1_value = core->pipe.REGS[op->reg_src1];
    }
    if (op->reg_src2 != -1) {
        if (op->reg_src2 == 0)
            op->reg_src2_value = 0;
        else if (core->pipe.mem_op && core->pipe.mem_op->reg_dst == op->reg_src2) {
            if (!core->pipe.mem_op->reg_dst_value_ready)
                stall = 1;
            else
                op->reg_src2_value = core->pipe.mem_op->reg_dst_value;
        }
        else if (core->pipe.wb_op && core->pipe.wb_op->reg_dst == op->reg_src2) {
            op->reg_src2_value = core->pipe.wb_op->reg_dst_value;
        }
        else
            op->reg_src2_value = core->pipe.REGS[op->reg_src2];
    }

    /* if bypassing requires a stall (e.g. use immediately after load),
     * return without clearing stage input */
    if (stall) 
        return;

    /* execute the op */
    switch (op->opcode) {
        case OP_SPECIAL:
            op->reg_dst_value_ready = 1;
            switch (op->subop) {
                case SUBOP_SYSCALL:
                    core->pipe.syscall_stall = 1;
                    break;
                case SUBOP_SLL:
                    op->reg_dst_value = op->reg_src2_value << op->shamt;
                    break;
                case SUBOP_SLLV:
                    op->reg_dst_value = op->reg_src2_value << op->reg_src1_value;
                    break;
                case SUBOP_SRL:
                    op->reg_dst_value = op->reg_src2_value >> op->shamt;
                    break;
                case SUBOP_SRLV:
                    op->reg_dst_value = op->reg_src2_value >> op->reg_src1_value;
                    break;
                case SUBOP_SRA:
                    op->reg_dst_value = (int32_t)op->reg_src2_value >> op->shamt;
                    break;
                case SUBOP_SRAV:
                    op->reg_dst_value = (int32_t)op->reg_src2_value >> op->reg_src1_value;
                    break;
                case SUBOP_JR:
                case SUBOP_JALR:
                    op->reg_dst_value = op->pc + 4;
                    op->branch_dest = op->reg_src1_value;
                    op->branch_taken = 1;
                    break;

                case SUBOP_MULT:
                    {
                        /* we set a result value right away; however, we will
                         * model a stall if the program tries to read the value
                         * before it's ready (or overwrite HI/LO). Also, if
                         * another multiply comes down the core->pipe later, it will
                         * update the values and re-set the stall cycle count
                         * for a new operation.
                         */
                        int64_t val = (int64_t)((int32_t)op->reg_src1_value) * (int64_t)((int32_t)op->reg_src2_value);
                        uint64_t uval = (uint64_t)val;
                        core->pipe.HI = (uval >> 32) & 0xFFFFFFFF;
                        core->pipe.LO = (uval >>  0) & 0xFFFFFFFF;

                        /* four-cycle multiplier latency */
                        core->pipe.multiplier_stall = 4;
                    }
                    break;
                case SUBOP_MULTU:
                    {
                        uint64_t val = (uint64_t)op->reg_src1_value * (uint64_t)op->reg_src2_value;
                        core->pipe.HI = (val >> 32) & 0xFFFFFFFF;
                        core->pipe.LO = (val >>  0) & 0xFFFFFFFF;

                        /* four-cycle multiplier latency */
                        core->pipe.multiplier_stall = 4;
                    }
                    break;

                case SUBOP_DIV:
                    if (op->reg_src2_value != 0) {

                        int32_t val1 = (int32_t)op->reg_src1_value;
                        int32_t val2 = (int32_t)op->reg_src2_value;
                        int32_t div, mod;

                        div = val1 / val2;
                        mod = val1 % val2;

                        core->pipe.LO = div;
                        core->pipe.HI = mod;
                    } else {
                        // really this would be a div-by-0 exception
                        core->pipe.HI = core->pipe.LO = 0;
                    }

                    /* 32-cycle divider latency */
                    core->pipe.multiplier_stall = 32;
                    break;

                case SUBOP_DIVU:
                    if (op->reg_src2_value != 0) {
                        core->pipe.HI = (uint32_t)op->reg_src1_value % (uint32_t)op->reg_src2_value;
                        core->pipe.LO = (uint32_t)op->reg_src1_value / (uint32_t)op->reg_src2_value;
                    } else {
                        /* really this would be a div-by-0 exception */
                        core->pipe.HI = core->pipe.LO = 0;
                    }

                    /* 32-cycle divider latency */
                    core->pipe.multiplier_stall = 32;
                    break;

                case SUBOP_MFHI:
                    /* stall until value is ready */
                    if (core->pipe.multiplier_stall > 0)
                        return;

                    op->reg_dst_value = core->pipe.HI;
                    break;
                case SUBOP_MTHI:
                    /* stall to respect WAW dependence */
                    if (core->pipe.multiplier_stall > 0)
                        return;

                    core->pipe.HI = op->reg_src1_value;
                    break;

                case SUBOP_MFLO:
                    /* stall until value is ready */
                    if (core->pipe.multiplier_stall > 0)
                        return;

                    op->reg_dst_value = core->pipe.LO;
                    break;
                case SUBOP_MTLO:
                    /* stall to respect WAW dependence */
                    if (core->pipe.multiplier_stall > 0)
                        return;

                    core->pipe.LO = op->reg_src1_value;
                    break;

                case SUBOP_ADD:
                case SUBOP_ADDU:
                    op->reg_dst_value = op->reg_src1_value + op->reg_src2_value;
                    break;
                case SUBOP_SUB:
                case SUBOP_SUBU:
                    op->reg_dst_value = op->reg_src1_value - op->reg_src2_value;
                    break;
                case SUBOP_AND:
                    op->reg_dst_value = op->reg_src1_value & op->reg_src2_value;
                    break;
                case SUBOP_OR:
                    op->reg_dst_value = op->reg_src1_value | op->reg_src2_value;
                    break;
                case SUBOP_NOR:
                    op->reg_dst_value = ~(op->reg_src1_value | op->reg_src2_value);
                    break;
                case SUBOP_XOR:
                    op->reg_dst_value = op->reg_src1_value ^ op->reg_src2_value;
                    break;
                case SUBOP_SLT:
                    op->reg_dst_value = ((int32_t)op->reg_src1_value <
                            (int32_t)op->reg_src2_value) ? 1 : 0;
                    break;
                case SUBOP_SLTU:
                    op->reg_dst_value = (op->reg_src1_value < op->reg_src2_value) ? 1 : 0;
                    break;
            }
            break;

        case OP_BRSPEC:
            switch (op->subop) {
                case BROP_BLTZ:
                case BROP_BLTZAL:
                    if ((int32_t)op->reg_src1_value < 0) op->branch_taken = 1;
                    break;

                case BROP_BGEZ:
                case BROP_BGEZAL:
                    if ((int32_t)op->reg_src1_value >= 0) op->branch_taken = 1;
                    break;
            }
            break;

        case OP_BEQ:
            if (op->reg_src1_value == op->reg_src2_value) op->branch_taken = 1;
            break;

        case OP_BNE:
            if (op->reg_src1_value != op->reg_src2_value) op->branch_taken = 1;
            break;

        case OP_BLEZ:
            if ((int32_t)op->reg_src1_value <= 0) op->branch_taken = 1;
            break;

        case OP_BGTZ:
            if ((int32_t)op->reg_src1_value > 0) op->branch_taken = 1;
            break;

        case OP_ADDI:
        case OP_ADDIU:
            op->reg_dst_value_ready = 1;
            op->reg_dst_value = op->reg_src1_value + op->se_imm16;
            break;
        case OP_SLTI:
            op->reg_dst_value_ready = 1;
            op->reg_dst_value = (int32_t)op->reg_src1_value < (int32_t)op->se_imm16 ? 1 : 0;
            break;
        case OP_SLTIU:
            op->reg_dst_value_ready = 1;
            op->reg_dst_value = (uint32_t)op->reg_src1_value < (uint32_t)op->se_imm16 ? 1 : 0;
            break;
        case OP_ANDI:
            op->reg_dst_value_ready = 1;
            op->reg_dst_value = op->reg_src1_value & op->imm16;
            break;
        case OP_ORI:
            op->reg_dst_value_ready = 1;
            op->reg_dst_value = op->reg_src1_value | op->imm16;
            break;
        case OP_XORI:
            op->reg_dst_value_ready = 1;
            op->reg_dst_value = op->reg_src1_value ^ op->imm16;
            break;
        case OP_LUI:
            op->reg_dst_value_ready = 1;
            op->reg_dst_value = op->imm16 << 16;
            break;

        case OP_LW:
        case OP_LH:
        case OP_LHU:
        case OP_LB:
        case OP_LBU:
            op->mem_addr = op->reg_src1_value + op->se_imm16;
            break;

        case OP_SW:
        case OP_SH:
        case OP_SB:
            op->mem_addr = op->reg_src1_value + op->se_imm16;
            op->mem_value = op->reg_src2_value;
            break;
    }

    printf("branch_taken: %d, predict_taken: %d, predicted_pc: %x, branch_dest: %x, BTmiss: %d\n", op->branch_taken, op->predict_taken, op->predicted_pc, op->branch_dest, op->BTBmiss);
    print_op(core->pipe.execute_op);
    /* handle branch recoveries at this point */
    if (op->is_branch){
      //printf("branch_taken: %d, predict_taken: %d, predicted_pc: %x, branch_dest: %x, BTmiss: %d\n", op->branch_taken, op->predict_taken, op->predicted_pc, op->branch_dest, op->BTBmiss);
      if (op->branch_taken && (!op->predict_taken || op->predicted_pc != op->branch_dest))
        pipe_recover(3, op->branch_dest);
      else if (!op->branch_taken && op->predict_taken)
        pipe_recover(3, (op->pc) + 4);
      else if (op->BTBmiss && !op->branch_taken)
        pipe_recover(3, (op->pc) + 4);
      else if (op->BTBmiss && op->branch_taken)
        pipe_recover(3, op->branch_dest);

    /* update the predictor tables */
      newBTB.tag = op->pc;
      newBTB.v = 1;
      newBTB.is_conditional = op->branch_cond;
      newBTB.target = op->branch_dest;
      update_predictor(op->branch_taken, newBTB);
    }


    /* remove from upstream stage and place in downstream stage */
    core->pipe.execute_op = NULL;
    core->pipe.mem_op = op;
}


void pipe_stage_decode()
{
    /* if downstream stall, return (and leave any input we had) */
    if (core->pipe.execute_op != NULL)
        return;

    /* if no op to decode, return */
    if (core->pipe.decode_op == NULL)
        return;

    if (core->pipe.syscall_stall)
        return;

    /* grab op and remove from stage input */
    Pipe_Op *op = core->pipe.decode_op;
    core->pipe.decode_op = NULL;

    /* set up info fields (source/dest regs, immediate, jump dest) as necessary */
    uint32_t opcode = (op->instruction >> 26) & 0x3F;
    uint32_t rs = (op->instruction >> 21) & 0x1F;
    uint32_t rt = (op->instruction >> 16) & 0x1F;
    uint32_t rd = (op->instruction >> 11) & 0x1F;
    uint32_t shamt = (op->instruction >> 6) & 0x1F;
    uint32_t funct1 = (op->instruction >> 0) & 0x1F;
    uint32_t funct2 = (op->instruction >> 0) & 0x3F;
    uint32_t imm16 = (op->instruction >> 0) & 0xFFFF;
    uint32_t se_imm16 = imm16 | ((imm16 & 0x8000) ? 0xFFFF8000 : 0);
    uint32_t targ = (op->instruction & ((1UL << 26) - 1)) << 2;

    op->opcode = opcode;
    op->imm16 = imm16;
    op->se_imm16 = se_imm16;
    op->shamt = shamt;

    switch (opcode) {
        case OP_SPECIAL:
            /* all "SPECIAL" insts are R-types that use the ALU and both source
             * regs. Set up source regs and immediate value. */
            op->reg_src1 = rs;
            op->reg_src2 = rt;
            op->reg_dst = rd;
            op->subop = funct2;
            if (funct2 == SUBOP_SYSCALL) {
                op->reg_src1 = 2; // v0
                op->reg_src2 = 3; // v1

                if (core->pipe.execute_op != NULL || 
                    core->pipe.mem_op != NULL || 
                    core->pipe.wb_op != NULL){

                    //stall for syscall
                    core->pipe.decode_op = op;
                    return;
                }
            }
            if (funct2 == SUBOP_JR || funct2 == SUBOP_JALR) {
                op->is_branch = 1;
                op->branch_cond = 0;
            }

            break;

        case OP_BRSPEC:
            /* branches that have -and-link variants come here */
            op->is_branch = 1;
            op->reg_src1 = rs;
            op->reg_src2 = rt;
            op->is_branch = 1;
            op->branch_cond = 1; /* conditional branch */
            op->branch_dest = op->pc + 4 + (se_imm16 << 2);
            op->subop = rt;
            if (rt == BROP_BLTZAL || rt == BROP_BGEZAL) {
                /* link reg */
                op->reg_dst = 31;
                op->reg_dst_value = op->pc + 4;
                op->reg_dst_value_ready = 1;
            }
            break;

        case OP_JAL:
            op->reg_dst = 31;
            op->reg_dst_value = op->pc + 4;
            op->reg_dst_value_ready = 1;
            op->branch_taken = 1;
            /* fallthrough */
        case OP_J:
            op->is_branch = 1;
            op->branch_cond = 0;
            op->branch_taken = 1;
            op->branch_dest = (op->pc & 0xF0000000) | targ;
            break;

        case OP_BEQ:
        case OP_BNE:
        case OP_BLEZ:
        case OP_BGTZ:
            /* ordinary conditional branches (resolved after execute) */
            op->is_branch = 1;
            op->branch_cond = 1;
            op->branch_dest = op->pc + 4 + (se_imm16 << 2);
            op->reg_src1 = rs;
            op->reg_src2 = rt;
            break;

        case OP_ADDI:
        case OP_ADDIU:
        case OP_SLTI:
        case OP_SLTIU:
            /* I-type ALU ops with sign-extended immediates */
            op->reg_src1 = rs;
            op->reg_dst = rt;
            break;

        case OP_ANDI:
        case OP_ORI:
        case OP_XORI:
        case OP_LUI:
            /* I-type ALU ops with non-sign-extended immediates */
            op->reg_src1 = rs;
            op->reg_dst = rt;
            break;

        case OP_LW:
        case OP_LH:
        case OP_LHU:
        case OP_LB:
        case OP_LBU:
        case OP_SW:
        case OP_SH:
        case OP_SB:
            /* memory ops */
            op->is_mem = 1;
            op->reg_src1 = rs;
            if (opcode == OP_LW || opcode == OP_LH || opcode == OP_LHU || opcode == OP_LB || opcode == OP_LBU) {
                /* load */
                op->mem_write = 0;
                op->reg_dst = rt;
            }
            else {
                /* store */
                op->mem_write = 1;
                op->reg_src2 = rt;
            }
            break;
    }

    /* we will handle reg-read together with bypass in the execute stage */

    /* place op in downstream slot */
    core->pipe.execute_op = op;
}

void pipe_stage_fetch()
{
  /////////////////////
  //INSTRUCTION CACHE//
  /////////////////////

    /* if core->pipeline is stalled (our output slot is not empty), return */
    if (core->pipe.decode_op != NULL)
        return;
    
  
    if (core->pipe.syscall_stall){
        core->pipe.syscall_stall = 0;
        return;
    }

    //check instruction cache for hit or miss
    if (!core->pipe.inst_stall){
      if (!inst_check(core->pipe.PC) || core->l1_inst_cache.miss.miss_cycles > 0){
            core->pipe.inst_stall = 1;
        }
    }
    if (core->l1_inst_cache.miss.zero == 1){
      core->l1_inst_cache.miss.zero = 0;
      core->pipe.inst_stall = 0;
    }

    if (l2_inst_hit_handler(core->pipe.PC)){
        core->pipe.inst_stall = 0;
        inst_load(core->pipe.PC, EXCLUSIVE);
    }      

  //if stalling then return
  if (core->pipe.inst_stall > 0)
    return;

  /////////////////////////
  //END INSTRUCTION CACHE//
  /////////////////////////  
  
  /* Allocate an op and send it down the core->pipeline. */
  Pipe_Op *op = malloc(sizeof(Pipe_Op));
  

  memset(op, 0, sizeof(Pipe_Op));
  op->reg_src1 = op->reg_src2 = op->reg_dst = -1;
  
  op->instruction = mem_read_32(core->pipe.PC);
  op->pc = core->pipe.PC;
  core->pipe.decode_op = op;

  /////////////
  //PREDICTOR//
  /////////////

  /*branch prediction*/
  op->predicted_pc = predict_branch(core->pipe.PC, &(op->predict_taken), &(op->BTBmiss));
  
  /////////////////
  //END PREDICTOR//
  /////////////////
  
  /* update PC */
  core->pipe.PC = op->predicted_pc;

  stat_inst_fetch++;

}


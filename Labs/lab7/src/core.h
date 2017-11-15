#include "objects.h"
#include "pipe.h"
#include "cache.h"
#include "predictor.h"

#ifndef _CORE_H_
#define _CORE_H_

typedef struct Core {
  int core_num;
  L1_Inst_Cache l1_inst_cache;
  L1_Data_Cache l1_data_cache;	
  struct Pipe_State pipe;
  struct Predictor predictor;
  int RUN_BIT;
  uint32_t* transfer;
} Core;

void init_core(int core_num);
void set_active_core(int core_num);
int spawn(int spawned_num, uint32_t syscall_pc);


#endif

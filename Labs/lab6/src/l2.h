#include <stdint.h>

#ifndef l2_H_
#define l2_H_

//My function delcarations


typedef struct HITREG {
  int v;
  int hit_cycles;
  int zero;
  uint32_t pc_mem_addr;
} HITREG;
 
typedef struct MSHR {
  int v;
  uint32_t pc_mem_addr;
  int done;
  uint32_t miss_cycles;
  int zero;
} MSHR;

//initialize the l2 cache
void l2_init();

//REMOVAL
void l2_remove_data_hit();
void l2_remove_inst_hit(uint32_t new_pc);

//HANDLERS
uint32_t l2_inst_hit_handler(uint32_t pc);
int l2_data_hit_handler(uint32_t mem_addr);
uint32_t l2_miss_handler();

//SCHEDULERS
void l2_inst_hit_scheduler(uint32_t pc);
void l2_data_hit_scheduler(uint32_t mem_addr);
void l2_miss_scheduler(uint32_t pc_mem_addr);

//HELPERS
void send_request_to_dram(int i);
void set_on_recover();

//update cycles
void l2_update_cycles();

//check l2 cache
int l2_check(uint32_t pc_mem_addr, int is_inst);

//load l2 cache
void l2_load(uint32_t pc_mem_addr);

#endif

#include <stdint.h>

#ifndef CACHE_H_
#define CACHE_H_

typedef struct block {
  int v;
  uint32_t tag;
  uint32_t timestamp;
  
} block;

//My function delcarations                                             

void data_init();
void inst_init();                 
int inst_check(uint32_t pc); 
void inst_load(uint32_t pc);
int data_check(uint32_t addr);
void data_load(uint32_t addr);

#endif

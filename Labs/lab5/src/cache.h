#include <stdint.h>

#ifndef CACHE_H_
#define CACHE_H_

typedef struct block {
  int v;
  double tag;
  uint32_t timestamp;
} block;

//My function delcarations                                             

void data_init();
void inst_init();                 
int inst_check(uint32_t pc, uint32_t time); 
void inst_load(uint32_t pc, uint32_t time);
int data_check(uint32_t addr, uint32_t time);
void data_load(uint32_t addr, uint32_t time);

#endif

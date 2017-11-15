#include <stdint.h>
#include "objects.h"

#ifndef CACHE_H_
#define CACHE_H_

//My function delcarations                                             

typedef struct L1_Inst_Cache {
	struct MSHR miss;
	struct block blocks[64][4];
} L1_Inst_Cache;

typedef struct L1_Data_Cache {
	struct MSHR miss;
	struct block blocks[256][8];
} L1_Data_Cache;

void init_l1_caches(); 
void init_cache_block(struct block* block);               
struct block* inst_check(uint32_t pc);
struct block* inst_probe(uint32_t pc);
void inst_load(uint32_t pc, int state);
struct block* data_check(uint32_t addr);
struct block* data_probe(uint32_t pc);
void data_load(uint32_t addr, int state, uint32_t* data);
int check_for_l2_misses(struct MSHR* miss);
void l1_miss_process(struct MSHR* miss);

#endif

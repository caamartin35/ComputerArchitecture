#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <math.h>
#include <limits.h>
#include <string.h>
#include "cache.h"
#include "pipe.h"
#include "l2.h"

struct block inst_cache[64][4];
struct block data_cache[256][8];

void inst_init(){
  int i;
  int j;

  for (i=0; i<64; i++){
    for (j=0; j<4; j++){
      inst_cache[i][j].v = 0;
      inst_cache[i][j].tag = 0;
      inst_cache[i][j].timestamp = 0;
    }
  }
}

void data_init(){
  int i;
  int j;

  for (i=0; i<256; i++){
    for (j=0; j<8; j++){
      data_cache[i][j].v = 0;
      data_cache[i][j].tag = 0;
      data_cache[i][j].timestamp = 0;
    }
  }
}

int data_check(uint32_t addr){
  int col;
  int setIndex;
  int tag;
  int retVal;

  setIndex = (addr >> 5) & 0xff;
  tag = (addr >> 13);

  //iterate through the blocks.                                                                                                                                        
  for (col=0; col<8; col++){
    //check each block to see if it is a hit.                                                                                                                          
    if ((data_cache[setIndex][col]).tag == tag){
      if ((data_cache[setIndex][col]).v == 1){
        return 1;
      }
    }
  }
  //since we missed, check the l2
  l2_check(addr, 0);
  return 0;
}

void data_load(uint32_t addr){
  struct block *LRU;
  int col;
  int setIndex;
  int tag;


  setIndex = (addr >> 5) & 0xff;
  tag = (addr >> 13);

  //iterate through the blocks.                                                                                                                                        
  for (col=0; col<8; col++){

    //set our LRU block to first block in set.               
    if (col == 0)
      LRU = data_cache[setIndex];
    
    //reset LRU if timestamp is less(older) on current block  
    if ((*LRU).timestamp > (data_cache[setIndex][col]).timestamp){
      LRU = data_cache[setIndex]+col;
    }
  }
  if (LRU->v == 1) printf("CACHE: DATA EVICTION!!!\n");
  //resetting the least recently used block                                                                                                                           
  LRU->v = 1;
  LRU->tag = tag;
  LRU->timestamp = pipe.time;
}


//checks if the cache will have a hit or miss, returns 1 on hit, 0 on miss
int inst_check(uint32_t pc){
  int col;
  int setIndex;
  int tag;
  int retVal;
  setIndex = (pc >> 5) & 0x3f;
  tag = (pc >> 11);
  //iterate through the blocks.                                                                                                                                       
  for (col=0; col<4; col++){

    //check each block to see if it is a hit.                                                                                                                         
    if ((inst_cache[setIndex][col]).tag == tag){
      if ((inst_cache[setIndex][col]).v == 1){
        return 1;
      }
    }
  }
  l2_check(pc, 1); 
  return 0;
}

//loads the instruction from the cache. returns 1 if it was a cache hit, 0 otherwise
void inst_load(uint32_t pc){
  
  int col;
  int setIndex;
  int tag;
  struct block *LRU;
  

  setIndex = (pc >> 5) & 0x3f;
  tag = (pc >> 11);

  //iterate through the blocks.
  for (col=0; col<4; col++){
    //set our LRU block to first block in set.
    if (col == 0)
      LRU = inst_cache[setIndex];

    //reset LRU if timestamp is less(older) on current block
    if ((*LRU).timestamp > (inst_cache[setIndex][col]).timestamp){
      LRU = inst_cache[setIndex]+col;
    }
  }
  if (LRU->v == 1) printf("CACHE: INSTRUCTION EVICTION!!!!!");
  //resetting the least recently used block
  LRU->v = 1;
  LRU->tag = tag;
  LRU->timestamp = pipe.time;
}



  
  

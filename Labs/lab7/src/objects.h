#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <math.h>
#include <limits.h>
#include <string.h>
#include <stdint.h>
#include "defines.h"

#ifndef _OBJECTS_H_
#define _OBJECTS_H_


typedef struct State_Machine{
  int state;
  int next_state;
} State_Machine;


/////////////
//L1 CACHES//
/////////////

//cache block structure
typedef struct block {
  int v;
  uint32_t tag;
  uint32_t timestamp;
  int dirty;
  uint32_t pc_mem_addr;
  int state;
  uint32_t data[8];
} block;

////////////
//L2 CACHE//
////////////

//hit register structure
typedef struct HITREG {
  int v;
  int hit_cycles;
  int zero;
  uint32_t pc_mem_addr;
} HITREG;
 
 //miss register structure
typedef struct MSHR {
  int v;
  uint32_t pc_mem_addr;
  int done;
  uint32_t miss_cycles;
  int zero;
  int is_inst;
  int is_write;
  int requester;
} MSHR;

/////////////////////
//MEMORY CONTROLLER//
/////////////////////

//dram request structure
typedef struct Request{
  uint32_t row;
  uint32_t bank;
  uint32_t time;
  uint32_t process_count;
  int source;
  MSHR* reg_ptr;
} Request;

//request queue structure
typedef struct Queue{
  uint32_t requests;
  uint32_t capacity;
  Request** queue;
} Queue;

////////
//DRAM//
////////

//the dram bank structure
//row open is -1 if all rows are closed in bank
typedef struct Bank{
  int row_open;
  int busy[350];
} Bank;

/////////////
//PREDICTOR//
/////////////

//BTB element structure
typedef struct BTBentry{
  uint32_t tag;
  int v;
  int is_conditional;
  uint32_t target;
} BTBentry;

/////////
//MASKS//
/////////

typedef struct closed_row_needed{
  int data_buf_needed[350];
  int command_buf_needed[350];
  int addr_buf_needed[350];
  int bank_needed[350];
} closed_row_needed;

typedef struct row_hit_needed{
  int data_buf_needed[350];
  int command_buf_needed[350];
  int addr_buf_needed[350];
  int bank_needed[350];
} row_hit_needed;

typedef struct row_miss_needed{
  int data_buf_needed[350];
  int command_buf_needed[350];
  int addr_buf_needed[350];
  int bank_needed[350];
} row_miss_needed;

#endif

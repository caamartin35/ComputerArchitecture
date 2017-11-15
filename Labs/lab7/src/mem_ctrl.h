#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <stdint.h> 
#include "l2.h"
#include "dram.h"
#include "pipe.h"
#include "cache.h"
#include "objects.h"

#ifndef _MEM_CTRL_H_
#define _MEM_CTRL_H_

//init
void init_mem_ctrl();
void init_dram();
void init_masks();

//making request queue in mem controller
Request* load_request(Request* request, MSHR* reg_ptr, int is_inst);
void queue_request(Request* request);
void remove_from_queue(Queue* queue, int index);

//every cycle scheduling functions
Request* schedule_request();

//helpers
int is_schedulable(Request* request);
int find_schedulables(Request* ptr);
int find_row_hits(Request* ptr, int schedulables);
int find_earliest(Request* ptr, int row_hits);
void set_channel_vals(Request* request);
void shift_channel_vals();

typedef struct Memory_Controller {
	Queue *q;
	Queue *processQ;
	DRAM *dram;
	closed_row_needed *crn;
	row_hit_needed *rhn;
	row_miss_needed *rmn;
	int request_index;
} Memory_controller;
#endif
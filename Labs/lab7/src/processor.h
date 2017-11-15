#include "core.h"
#include "l2.h"
#include "mem_ctrl.h"
#include "dram.h"
#include "shell.h"

#ifndef _PROCESSOR_H_
#define _PROCESSOR_H_

typedef struct Processor {
	struct Core core0;
	struct Core core1;
	struct Core core2;
	struct Core core3;
	struct L2 l2;
	struct Memory_Controller mem_ctrl;
	uint32_t time;
} Processor;

extern Processor processor;

//core point to switch between them
extern Core* core;

void init_processor();

#endif
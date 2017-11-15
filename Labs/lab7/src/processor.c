#include "processor.h"
#include "pipe.h"
#include "cache.h"
#include "predictor.h"
#include "core.h"
#include "l2.h"
#include "mem_ctrl.h"
#include "dram.h"


//declare our processor struct
Processor processor;

//declare core pointer to switch between cores
Core* core;


void init_processor(){
	init_l2();
	init_mem_ctrl();
	init_dram();
	init_masks();
	
	init_core(0);
	init_core(1);
	init_core(2);
	init_core(3);

	processor.time = 0;
}

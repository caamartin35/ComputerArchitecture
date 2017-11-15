#include <stdint.h>
#include "core.h"
#include "processor.h"
#include "pipe.h"
#include "predictor.h"

//initializes one core
void init_core(int core_num){
	set_active_core(core_num);
	core->core_num = core_num;
	init_predictor();
	init_l1_caches();
	init_pipe();
	core->transfer = malloc(8*sizeof(uint32_t));
}

//sets our active core to core core_num
void set_active_core(int core_num){
	switch (core_num){
		case 0:
			core = &(processor.core0);
			break;
		case 1:
			core = &(processor.core1);
			break;
		case 2:
			core = &(processor.core2);
			break;
		case 3:
			core = &(processor.core3);
			break;
	}
}
//returns 1 if successfully spawned, 0 if cpu had already been spawned
int spawn(int spawned_num, uint32_t syscall_pc){
	struct Core* spawned_core;
	struct Core* calling_core = core;

	//set pointer to the newly spawned core
	switch (spawned_num){
		case 0:
			spawned_core = &(processor.core0);
			break;
		case 1:
			spawned_core = &(processor.core1);
			break;
		case 2:
			spawned_core = &(processor.core2);
			break;
		case 3:
			spawned_core = &(processor.core3);
			break;
	}

	//if thread is already running, don't spawn again
	if (spawned_core->RUN_BIT){
		return 0;
	}
	else {
		//set values to denote a spawn
		calling_core->pipe.REGS[3] = 0;
		spawned_core->pipe.REGS[3] = 1;
		spawned_core->pipe.PC = syscall_pc + 4;
		spawned_core->RUN_BIT = 1;
		return 1;
	}
}

#include "mem_ctrl.h"
#include "objects.h"
#include "processor.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>

//initialize the mem controller
void init_mem_ctrl(){
  processor.mem_ctrl.q = malloc(sizeof(Queue));
  processor.mem_ctrl.q->queue = malloc(sizeof(Request*));
  processor.mem_ctrl.q->queue[0] = malloc(sizeof(Request*));
  processor.mem_ctrl.processQ = malloc(sizeof(Queue));
  processor.mem_ctrl.processQ = malloc(sizeof(Request*));
  processor.mem_ctrl.q->requests = 0;
  processor.mem_ctrl.q->capacity = 0;
  processor.mem_ctrl.processQ->requests = 0;
  processor.mem_ctrl.processQ->capacity = 0;
}

//initialize processor.mem_ctrl.dram structure
void init_dram(){
  processor.mem_ctrl.dram = malloc(sizeof(DRAM));
  for (int i=0;i<350;i++){
    processor.mem_ctrl.dram->data_buf_busy[i] = 0;
    processor.mem_ctrl.dram->command_buf_busy[i] = 0;
    processor.mem_ctrl.dram->addr_buf_busy[i] = 0;
    for (int j=0; j<8; j++){
      (processor.mem_ctrl.dram->banks[j]).row_open = -1;
      (processor.mem_ctrl.dram->banks[j]).busy[i] = 0;
    }
   
  }
}

//initialize processor.mem_ctrl.dram buffer masks
void init_masks(){
  processor.mem_ctrl.crn = malloc(sizeof(closed_row_needed));
  processor.mem_ctrl.rhn = malloc(sizeof(row_hit_needed));
  processor.mem_ctrl.rmn = malloc(sizeof(row_miss_needed));

  //initlialize all to 0
  for (int i=0; i<350; i++){
    processor.mem_ctrl.crn->data_buf_needed[i] = 0;
    processor.mem_ctrl.crn->command_buf_needed[i] = 0;
    processor.mem_ctrl.crn->addr_buf_needed[i] = 0;
    processor.mem_ctrl.crn->bank_needed[i] = 0;

    processor.mem_ctrl.rhn->data_buf_needed[i] = 0;
    processor.mem_ctrl.rhn->command_buf_needed[i] = 0;
    processor.mem_ctrl.rhn->addr_buf_needed[i] = 0;
    processor.mem_ctrl.rhn->bank_needed[i] = 0;

    processor.mem_ctrl.rmn->data_buf_needed[i] = 0;
    processor.mem_ctrl.rmn->command_buf_needed[i] = 0;
    processor.mem_ctrl.rmn->addr_buf_needed[i] = 0;
    processor.mem_ctrl.rmn->bank_needed[i] = 0;
  }

  //closed row mask
  for(int i=200; i<250; i++){
    processor.mem_ctrl.crn->data_buf_needed[i] = 1;
  }
  for(int i=0; i<200; i++){
    processor.mem_ctrl.crn->bank_needed[i] = 1;
  }
  processor.mem_ctrl.crn->command_buf_needed[0] = 1;
  processor.mem_ctrl.crn->command_buf_needed[1] = 1;
  processor.mem_ctrl.crn->command_buf_needed[2] = 1;
  processor.mem_ctrl.crn->command_buf_needed[3] = 1;
  processor.mem_ctrl.crn->addr_buf_needed[0] = 1;
  processor.mem_ctrl.crn->addr_buf_needed[1] = 1;
  processor.mem_ctrl.crn->addr_buf_needed[2] = 1;
  processor.mem_ctrl.crn->addr_buf_needed[3] = 1;
  processor.mem_ctrl.crn->command_buf_needed[100] = 1;
  processor.mem_ctrl.crn->command_buf_needed[101] = 1;
  processor.mem_ctrl.crn->command_buf_needed[102] = 1;
  processor.mem_ctrl.crn->command_buf_needed[103] = 1;
  processor.mem_ctrl.crn->addr_buf_needed[100] = 1;
  processor.mem_ctrl.crn->addr_buf_needed[101] = 1;
  processor.mem_ctrl.crn->addr_buf_needed[102] = 1;
  processor.mem_ctrl.crn->addr_buf_needed[103] = 1;

  //row hit mask
  for (int i=100; i<150; i++){
    processor.mem_ctrl.rhn->data_buf_needed[i] = 1;
  }
  for (int i=0; i<100; i++){
    processor.mem_ctrl.rhn->bank_needed[i] = 1;
  }
  processor.mem_ctrl.rhn->command_buf_needed[0] = 1;
  processor.mem_ctrl.rhn->command_buf_needed[1] = 1;
  processor.mem_ctrl.rhn->command_buf_needed[2] = 1;
  processor.mem_ctrl.rhn->command_buf_needed[3] = 1;
  processor.mem_ctrl.rhn->addr_buf_needed[0] = 1;
  processor.mem_ctrl.rhn->addr_buf_needed[1] = 1;
  processor.mem_ctrl.rhn->addr_buf_needed[2] = 1;
  processor.mem_ctrl.rhn->addr_buf_needed[3] = 1;

  //row miss mask
  for(int i=300; i<350; i++){
    processor.mem_ctrl.rmn->data_buf_needed[i] = 1;
  }
  for(int i=0; i<300; i++){
    processor.mem_ctrl.rmn->bank_needed[i] = 1;
  }

  processor.mem_ctrl.rmn->command_buf_needed[0] = 1;
  processor.mem_ctrl.rmn->command_buf_needed[1] = 1;
  processor.mem_ctrl.rmn->command_buf_needed[2] = 1;
  processor.mem_ctrl.rmn->command_buf_needed[3] = 1;
  processor.mem_ctrl.rmn->addr_buf_needed[0] = 1;
  processor.mem_ctrl.rmn->addr_buf_needed[1] = 1;
  processor.mem_ctrl.rmn->addr_buf_needed[2] = 1;
  processor.mem_ctrl.rmn->addr_buf_needed[3] = 1;
  processor.mem_ctrl.rmn->command_buf_needed[100] = 1;
  processor.mem_ctrl.rmn->command_buf_needed[101] = 1;
  processor.mem_ctrl.rmn->command_buf_needed[102] = 1;
  processor.mem_ctrl.rmn->command_buf_needed[103] = 1;
  processor.mem_ctrl.rmn->addr_buf_needed[100] = 1;
  processor.mem_ctrl.rmn->addr_buf_needed[101] = 1;
  processor.mem_ctrl.rmn->addr_buf_needed[102] = 1;
  processor.mem_ctrl.rmn->addr_buf_needed[103] = 1;
  processor.mem_ctrl.rmn->command_buf_needed[200] = 1;
  processor.mem_ctrl.rmn->command_buf_needed[201] = 1;
  processor.mem_ctrl.rmn->command_buf_needed[202] = 1;
  processor.mem_ctrl.rmn->command_buf_needed[203] = 1;
  processor.mem_ctrl.rmn->addr_buf_needed[200] = 1;
  processor.mem_ctrl.rmn->addr_buf_needed[201] = 1;
  processor.mem_ctrl.rmn->addr_buf_needed[202] = 1;
  processor.mem_ctrl.rmn->addr_buf_needed[203] = 1;

}
//load register into request object                                                                                
Request* load_request(Request* request, MSHR* reg_ptr, int is_inst){
  if (reg_ptr != NULL){
    printf("MEM_CTRL: Loading with addr: %x\n", reg_ptr->pc_mem_addr);
    request->reg_ptr = reg_ptr;
    request->bank = ((reg_ptr->pc_mem_addr) >> 5) & 0x07;
    request->row = ((reg_ptr->pc_mem_addr) >> 16);
    request->time = processor.time;
    request->source = is_inst;
    request->process_count = 0;
    return request;
  }
  else {
    return NULL;
  }
}

//insert request object into queue
void queue_request(Request *request){
  int i;
  printf("MEMCTRL: IN QUEUE_REQUEST with requests=%d, capacity=%d\n", processor.mem_ctrl.q->requests, processor.mem_ctrl.q->capacity);
  MSHR* temp_ptr = request->reg_ptr;
  int temp_bank = request->bank;
  int temp_row = request->row;
  int temp_source = request->source;
  uint32_t temp_time = request->time;
  //if our queue has no more room, make more
  if (processor.mem_ctrl.q->requests == processor.mem_ctrl.q->capacity){
    printf("MEMCTRL: Request Queue full, making more room\n");
    processor.mem_ctrl.q->queue = realloc(processor.mem_ctrl.q->queue, (processor.mem_ctrl.q->capacity+1)*sizeof(Request*));
    for (i=0; i<processor.mem_ctrl.q->capacity+1; i++)
      processor.mem_ctrl.q->queue[i] = realloc(processor.mem_ctrl.q->queue[i], sizeof(Request));
    processor.mem_ctrl.q->queue[processor.mem_ctrl.q->capacity]->reg_ptr = temp_ptr;
    processor.mem_ctrl.q->queue[processor.mem_ctrl.q->capacity]->bank = temp_bank;
    processor.mem_ctrl.q->queue[processor.mem_ctrl.q->capacity]->row = temp_row;
    processor.mem_ctrl.q->queue[processor.mem_ctrl.q->capacity]->source = temp_source;
    processor.mem_ctrl.q->queue[processor.mem_ctrl.q->capacity]->time = temp_time;
    processor.mem_ctrl.q->capacity++;
    processor.mem_ctrl.q->requests++;
    i -= 1;
  }
  else{
    printf("MEMCTRL: Extra room in the queue\n");
    for(i=0; i<processor.mem_ctrl.q->capacity; i++){
      if (processor.mem_ctrl.q->queue[i] == NULL){
      	processor.mem_ctrl.q->queue[i] = malloc(sizeof(Request));
      	processor.mem_ctrl.q->queue[i]->reg_ptr = temp_ptr;
      	processor.mem_ctrl.q->queue[i]->bank = temp_bank;
      	processor.mem_ctrl.q->queue[i]->row = temp_row;
      	processor.mem_ctrl.q->queue[i]->source = temp_source;
      	processor.mem_ctrl.q->queue[i]->time = temp_time;
      	printf("q of 0: bank: %d\n", processor.mem_ctrl.q->queue[0]->bank);
      	break;
      }
    }
    processor.mem_ctrl.q->requests++;
  }
  processor.mem_ctrl.request_index = i;
  printf("MEMCTRL: Done queueing with request_index=%d, requests=%d, capacity=%d\n", processor.mem_ctrl.request_index, processor.mem_ctrl.q->requests, processor.mem_ctrl.q->capacity);
}

//insert request into processing queue
void process_queue_request(Request* request){
  MSHR* temp_ptr = request->reg_ptr;
  int temp_bank = request->bank;
  int temp_row = request->row;
  int temp_source = request->source;
  uint32_t temp_time = request->time;
  int temp_process_count = request->process_count;

  //if our queue has no more room, make more                         
  if (processor.mem_ctrl.processQ->requests == processor.mem_ctrl.processQ->capacity){
     processor.mem_ctrl.processQ->queue = realloc(processor.mem_ctrl.processQ->queue, (processor.mem_ctrl.processQ->capacity+1)*sizeof(Request*));
     for (int i=0; i<processor.mem_ctrl.processQ->capacity+1; i++)
       processor.mem_ctrl.processQ->queue[i] = realloc(processor.mem_ctrl.processQ->queue[i], sizeof(Request));

     processor.mem_ctrl.processQ->queue[processor.mem_ctrl.processQ->capacity]->reg_ptr = temp_ptr;
     processor.mem_ctrl.processQ->queue[processor.mem_ctrl.processQ->capacity]->bank = temp_bank;
     processor.mem_ctrl.processQ->queue[processor.mem_ctrl.processQ->capacity]->row = temp_row;
     processor.mem_ctrl.processQ->queue[processor.mem_ctrl.processQ->capacity]->source = temp_source;
     processor.mem_ctrl.processQ->queue[processor.mem_ctrl.processQ->capacity]->time = temp_time;
     processor.mem_ctrl.processQ->queue[processor.mem_ctrl.processQ->capacity]->process_count = temp_process_count;
     processor.mem_ctrl.processQ->capacity++;
     processor.mem_ctrl.processQ->requests++;
  }
  else{
    for(int i=0; i<processor.mem_ctrl.processQ->capacity; i++){
      if (processor.mem_ctrl.processQ->queue[i] == NULL){
        processor.mem_ctrl.processQ->queue[i] = malloc(sizeof(Request));
        processor.mem_ctrl.processQ->queue[i]->reg_ptr = temp_ptr;
        processor.mem_ctrl.processQ->queue[i]->bank = temp_bank;
        processor.mem_ctrl.processQ->queue[i]->row = temp_row;
        processor.mem_ctrl.processQ->queue[i]->source = temp_source;
        processor.mem_ctrl.processQ->queue[i]->time = temp_time;
        processor.mem_ctrl.processQ->queue[i]->process_count = temp_process_count;
        break;
      }
    }
    processor.mem_ctrl.processQ->requests++;
  }
}

//every cycle schedule requests                     
Request* schedule_request(){
  Request** ptr = malloc(sizeof(Request*));
  Request ret;
  int schedulables = 0;
  int row_hits = 0;
  int early_tie = 0;
  printf("MEMCTRL: Scheduling request\n");
  *ptr = malloc(sizeof(Request));
  //get all the schedulables, if none, then no request is scheduled, if one, then schedule it
  schedulables = find_schedulables(*ptr);
  printf("MEMCTRL: Schedulables=%d\n", schedulables);
  if (schedulables == 0){
    free(*ptr);
    free(ptr);
    return NULL;
  }
  else if (schedulables == 1){
    return *ptr;
  }

  //find all row hits in the schedulables array, if there is only one, schedule it.
  row_hits = find_row_hits(*ptr, schedulables);
  printf("MEMCTRL: Row Hits=%d\n", row_hits);
  if (row_hits == 1){
    return *ptr;
  }

  //find the earliest request, returns 1 if there is a tie between two requests, 0 otherwise
  early_tie = find_earliest(*ptr, row_hits);
  printf("MEMCTRL: tie=%d\n", early_tie);
  if (!early_tie){
    return *ptr;
  }

  //we have an early tie, so we find which one is from the memory and schedule it
  if (ptr[0][0].source == 0){
    return &(ptr[0][0]);
  }
  else{
    return &(ptr[0][1]);
  }
    
}



///////////
//helpers//
///////////


//finds schedulables, returns number of schedulables found
int find_schedulables(Request* ptr){
  int schedulables = 0;
  printf("MEMCTRL: Finding Schedulables with capacity=%d, requests=%d\n", processor.mem_ctrl.q->capacity, processor.mem_ctrl.q->requests);
  for (int i=0; i<processor.mem_ctrl.q->capacity; i++){
    if (processor.mem_ctrl.q->queue[i] != NULL && is_schedulable(processor.mem_ctrl.q->queue[i]) > 0){
      printf("MEMCTRL: processor.mem_ctrl.q->queue[i]: %p\n", processor.mem_ctrl.q->queue[i]);
      schedulables++;
      ptr = realloc(ptr, schedulables*sizeof(Request));
      ptr[schedulables-1] = *(processor.mem_ctrl.q->queue[i]);
    }
  }
  return schedulables;
}

//finds row hits, returns number of row hits found
int find_row_hits(Request* ptr, int schedulables){
  int row_hits = 0;
  Request* hit_ptr;

  for (int i=0; i<schedulables; i++){
    if (ptr[i].row == (processor.mem_ctrl.dram->banks[ptr[i].bank]).row_open){
      row_hits++;
      hit_ptr = realloc(hit_ptr, row_hits*sizeof(Request));
      hit_ptr[row_hits-1] = ptr[i];
    }
  }
  ptr=hit_ptr;
  free(hit_ptr);
  return row_hits;
}
      
//finds earliest request, returns 1 if there is a tie, 0 if there is no tie
int find_earliest(Request* ptr, int row_hits){
  Request* earliest;
  int early_index;

  //search for initial earliest
  for (int i=0; i<row_hits; i++){
    if (i==0) {
      (*earliest) = ptr[i];
      early_index = 0;
    }
    else{
      if (earliest->time > ptr[i].time){
	(*earliest) = ptr[i];
	early_index = i;
      }
    }
  }

  //now that we know the earliest time, we can see if there is a tie
  for (int i=0; i<row_hits; i++){
    if (earliest->time == ptr[i].time && i != early_index){
      earliest = realloc(earliest, 2*sizeof(Request));
      earliest[1] = ptr[i];
      ptr = earliest;
      return 1;
    }
  }
 
  ptr = earliest;
  free(earliest);
  return 0;
}
	 
//returns 1 if schedulable, 0 otherwise
int is_schedulable(Request* request){

  printf("MEMCTRL: is_schedulable, request->bank=%d, processor.mem_ctrl.dram->banks[request->bank].row_open=%d\n", request->bank, processor.mem_ctrl.dram->banks[request->bank].row_open);
  //if row buffer is closed
  if (processor.mem_ctrl.dram->banks[request->bank].row_open == -1){
    printf("MEMCTRL: In is_schedulable, row closed\n");
    for (int i=0; i<350; i++){
      if (processor.mem_ctrl.dram->data_buf_busy[i] & processor.mem_ctrl.crn->data_buf_needed[i]){
	printf("MEMCTRL: Conflict with busy bank: Bank=%d, i=%d, busy=%d, needed=%d\n", request->bank, i, processor.mem_ctrl.dram->data_buf_busy[i], processor.mem_ctrl.crn->data_buf_needed[i]);
	return 0;
      }
      if (processor.mem_ctrl.dram->command_buf_busy[i] & processor.mem_ctrl.crn->command_buf_needed[i]) {
	printf("MEMCTRL: Conflict with busy bank: Bank=%d, i=%d, busy=%d, needed=%d\n", request->bank, i, processor.mem_ctrl.dram->command_buf_busy[i], processor.mem_ctrl.crn->command_buf_needed[i]);
	return 0;
      }
      if (processor.mem_ctrl.dram->addr_buf_busy[i] & processor.mem_ctrl.crn->addr_buf_needed[i]) {
       	printf("MEMCTRL: Conflict with busy addr buf: Bank=%d, i=%d, busy=%d, needed=%d\n", request->bank, i, processor.mem_ctrl.dram->addr_buf_busy[i], processor.mem_ctrl.crn->addr_buf_needed[i]);
	return 0;
      }
      if (processor.mem_ctrl.dram->banks[request->bank].busy[i] & processor.mem_ctrl.crn->bank_needed[i]){
	printf("MEMCTRL: Conflict with busy bank: Bank=%d, i=%d, busy=%d, needed=%d\n", request->bank, i, processor.mem_ctrl.dram->banks[request->bank].busy[i], processor.mem_ctrl.crn->bank_needed[i]);
	return 0;
      }
    }
    return 1;
  }    

  //its a row hit                                                                                                                            
  else if (processor.mem_ctrl.dram->banks[request->bank].row_open == request->row){
    printf("MEMCTRL: In is_schedulable, row hit\n");
    for (int i=0; i<350; i++){
      if (processor.mem_ctrl.dram->data_buf_busy[i] & processor.mem_ctrl.rhn->data_buf_needed[i]) return 0;
      if (processor.mem_ctrl.dram->command_buf_busy[i] & processor.mem_ctrl.rhn->command_buf_needed[i]) return 0;
      if (processor.mem_ctrl.dram->addr_buf_busy[i] & processor.mem_ctrl.rhn->addr_buf_needed[i]) return 0;
      if (processor.mem_ctrl.dram->banks[request->bank].busy[i] & processor.mem_ctrl.rhn->bank_needed[i]) return 0;
    }
    return 1;
  }

  //its a row miss
  else{
    printf("MEMCTRL: In is_schedulable, row miss\n");
    for (int i=0; i<350; i++){
      if (processor.mem_ctrl.dram->data_buf_busy[i] & processor.mem_ctrl.rmn->data_buf_needed[i]) return 0;
      if (processor.mem_ctrl.dram->command_buf_busy[i] & processor.mem_ctrl.rmn->command_buf_needed[i]) return 0;
      if (processor.mem_ctrl.dram->addr_buf_busy[i] & processor.mem_ctrl.rmn->addr_buf_needed[i]) return 0;
      if (processor.mem_ctrl.dram->banks[request->bank].busy[i] & processor.mem_ctrl.rmn->bank_needed[i]) return 0;
    }
    return 1;
  }
  
}


//set_channel_values
void set_channel_vals(Request* request){

  //if the row buffer is closed
  printf("0=%d,1=%d,2=%d,3=%d,4=%d,5=%d,6=%d,7=%d\n", processor.mem_ctrl.dram->banks[0].row_open,processor.mem_ctrl.dram->banks[1].row_open,processor.mem_ctrl.dram->banks[2].row_open,processor.mem_ctrl.dram->banks[3].row_open,processor.mem_ctrl.dram->banks[4].row_open,processor.mem_ctrl.dram->banks[5].row_open,processor.mem_ctrl.dram->banks[6].row_open,processor.mem_ctrl.dram->banks[7].row_open);
  if (processor.mem_ctrl.dram->banks[request->bank].row_open == -1){
    for (int i=0; i<350; i++){
      processor.mem_ctrl.dram->data_buf_busy[i] = processor.mem_ctrl.dram->data_buf_busy[i] | processor.mem_ctrl.crn->data_buf_needed[i];
      processor.mem_ctrl.dram->command_buf_busy[i] = processor.mem_ctrl.dram->command_buf_busy[i] | processor.mem_ctrl.crn->command_buf_needed[i];
      processor.mem_ctrl.dram->addr_buf_busy[i] = processor.mem_ctrl.dram->addr_buf_busy[i] | processor.mem_ctrl.crn->addr_buf_needed[i];
      processor.mem_ctrl.dram->banks[request->bank].busy[i] = processor.mem_ctrl.dram->banks[request->bank].busy[i] | processor.mem_ctrl.crn->bank_needed[i];
    }
    request->process_count = 250;
  }

  //its a row hit
  else if (processor.mem_ctrl.dram->banks[request->bank].row_open == request->row){
    for (int i=0; i<350; i++){
      processor.mem_ctrl.dram->data_buf_busy[i] = processor.mem_ctrl.dram->data_buf_busy[i] | processor.mem_ctrl.rhn->data_buf_needed[i];
      processor.mem_ctrl.dram->command_buf_busy[i] = processor.mem_ctrl.dram->command_buf_busy[i] | processor.mem_ctrl.rhn->command_buf_needed[i];
      processor.mem_ctrl.dram->addr_buf_busy[i] = processor.mem_ctrl.dram->addr_buf_busy[i] | processor.mem_ctrl.rhn->addr_buf_needed[i];
      processor.mem_ctrl.dram->banks[request->bank].busy[i] = processor.mem_ctrl.dram->banks[request->bank].busy[i] | processor.mem_ctrl.rhn->bank_needed[i];
    }
    request->process_count = 150;
  }

  //its a row miss
  else {
    for (int i=0; i<350; i++){
      processor.mem_ctrl.dram->data_buf_busy[i] = processor.mem_ctrl.dram->data_buf_busy[i] | processor.mem_ctrl.rmn->data_buf_needed[i];
      processor.mem_ctrl.dram->command_buf_busy[i] = processor.mem_ctrl.dram->command_buf_busy[i] | processor.mem_ctrl.rmn->command_buf_needed[i];
      processor.mem_ctrl.dram->addr_buf_busy[i] = processor.mem_ctrl.dram->addr_buf_busy[i] | processor.mem_ctrl.rmn->addr_buf_needed[i];
      processor.mem_ctrl.dram->banks[request->bank].busy[i] = processor.mem_ctrl.dram->banks[request->bank].busy[i] | processor.mem_ctrl.rmn->bank_needed[i];
    }
    request->process_count = 350;
  }
  
  process_queue_request(request);
  processor.mem_ctrl.dram->banks[request->bank].row_open = request->row;
  printf("MEMCTRL: Just set values, Bank=%d, row open=%d\n", request->bank, processor.mem_ctrl.dram->banks[request->bank].row_open);
  remove_from_queue(processor.mem_ctrl.q, processor.mem_ctrl.request_index);
}

//shift the channel values every cycle
void shift_channel_vals(){
  for (int i=1; i<350; i++){
    processor.mem_ctrl.dram->data_buf_busy[i-1] = processor.mem_ctrl.dram->data_buf_busy[i];
    processor.mem_ctrl.dram->command_buf_busy[i-1] = processor.mem_ctrl.dram->command_buf_busy[i];
    processor.mem_ctrl.dram->addr_buf_busy[i-1] = processor.mem_ctrl.dram->addr_buf_busy[i];
    for (int j=0; j<8; j++){
      processor.mem_ctrl.dram->banks[j].busy[i-1] = processor.mem_ctrl.dram->banks[j].busy[i];
    }
  }


  processor.mem_ctrl.dram->data_buf_busy[349] = 0;
  processor.mem_ctrl.dram->command_buf_busy[349] = 0;
  processor.mem_ctrl.dram->addr_buf_busy[349] = 0;
  for (int j=0; j<8; j++){
    processor.mem_ctrl.dram->banks[j].busy[349] = 0;
  }

  //decrement all process counts for requests being processed
  //if it is zero then we know processor.mem_ctrl.dram is done processing so we set the done bit for the corresponding MSHR
  //and remove it from the process list
  for (int i=0; i<processor.mem_ctrl.processQ->capacity; i++){
    if (processor.mem_ctrl.processQ->queue[i] != NULL){
      printf("MEMCTRL: Processing Request: Process_count=%d\n", processor.mem_ctrl.processQ->queue[i]->process_count);
      (processor.mem_ctrl.processQ->queue[i])->process_count--;
      if ((processor.mem_ctrl.processQ->queue[i])->process_count == 0){
	printf("MEMCTRL: Processing Done, Sending Fill Notification to L2");
	//	processor.mem_ctrl.dram->banks[(processor.mem_ctrl.processQ->queue[i])->bank].row_open = -1;
	((processor.mem_ctrl.processQ->queue[i])->reg_ptr)->done = 1;
	remove_from_queue(processor.mem_ctrl.processQ, i);
      }
    }
  }
}

void remove_from_queue(Queue* queue, int index){
  printf("MEMCTRL: In remove_from_queue with: capacity=%d\n, index=%d", queue->capacity, index);
  for (int i=0; i<queue->capacity; i++){
    if (queue->queue[i] != NULL && i == index) {
      printf("THIS WILL SHOW THEM!!!: i=%d, Bank=%d, Row=%d, process_count=%d, time=%d, source=%d\n", i, queue->queue[index]->bank, queue->queue[index]->row, queue->queue[index]->process_count, queue->queue[index]->time, queue->queue[index]->source);    
      free(queue->queue[index]);
      queue->queue[index] = NULL;
      queue->requests--;
      printf("requests: %d\n", queue->requests);
      printf("MEMCTRL: Removed Request\n");
    }
  }
}

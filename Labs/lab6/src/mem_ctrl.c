#include "mem_ctrl.h"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>

//initialize the mem controller
void mem_ctrl_init(){
  q = malloc(sizeof(Queue));
  //q->queue = malloc(sizeof(Request*));
  //q->queue[0] = malloc(sizeof(Request*));
  processQ = malloc(sizeof(Queue));
  //processQ = malloc(sizeof(Request*));
  q->requests = 0;
  q->capacity = 0;
  processQ->requests = 0;
  processQ->capacity = 0;
}

//initialize dram structure
void dram_init(){
  dram = malloc(sizeof(DRAM));
  for (int i=0;i<350;i++){
    dram->data_buf_busy[i] = 0;
    dram->command_buf_busy[i] = 0;
    dram->addr_buf_busy[i] = 0;
    for (int j=0; j<8; j++){
      (dram->banks[j]).row_open = -1;
      (dram->banks[j]).busy[i] = 0;
    }
   
  }
}

//initialize dram buffer masks
void masks_init(){
  crn = malloc(sizeof(closed_row_needed));
  rhn = malloc(sizeof(row_hit_needed));
  rmn = malloc(sizeof(row_miss_needed));

  //initlialize all to 0
  for (int i=0; i<350; i++){
    crn->data_buf_needed[i] = 0;
    crn->command_buf_needed[i] = 0;
    crn->addr_buf_needed[i] = 0;
    crn->bank_needed[i] = 0;

    rhn->data_buf_needed[i] = 0;
    rhn->command_buf_needed[i] = 0;
    rhn->addr_buf_needed[i] = 0;
    rhn->bank_needed[i] = 0;

    rmn->data_buf_needed[i] = 0;
    rmn->command_buf_needed[i] = 0;
    rmn->addr_buf_needed[i] = 0;
    rmn->bank_needed[i] = 0;
  }

  //closed row mask
  for(int i=200; i<250; i++){
    crn->data_buf_needed[i] = 1;
  }
  for(int i=0; i<200; i++){
    crn->bank_needed[i] = 1;
  }
  crn->command_buf_needed[0] = 1;
  crn->command_buf_needed[1] = 1;
  crn->command_buf_needed[2] = 1;
  crn->command_buf_needed[3] = 1;
  crn->addr_buf_needed[0] = 1;
  crn->addr_buf_needed[1] = 1;
  crn->addr_buf_needed[2] = 1;
  crn->addr_buf_needed[3] = 1;
  crn->command_buf_needed[100] = 1;
  crn->command_buf_needed[101] = 1;
  crn->command_buf_needed[102] = 1;
  crn->command_buf_needed[103] = 1;
  crn->addr_buf_needed[100] = 1;
  crn->addr_buf_needed[101] = 1;
  crn->addr_buf_needed[102] = 1;
  crn->addr_buf_needed[103] = 1;

  //row hit mask
  for (int i=100; i<150; i++){
    rhn->data_buf_needed[i] = 1;
  }
  for (int i=0; i<100; i++){
    rhn->bank_needed[i] = 1;
  }
  rhn->command_buf_needed[0] = 1;
  rhn->command_buf_needed[1] = 1;
  rhn->command_buf_needed[2] = 1;
  rhn->command_buf_needed[3] = 1;
  rhn->addr_buf_needed[0] = 1;
  rhn->addr_buf_needed[1] = 1;
  rhn->addr_buf_needed[2] = 1;
  rhn->addr_buf_needed[3] = 1;

  //row miss mask
  for(int i=300; i<350; i++){
    rmn->data_buf_needed[i] = 1;
  }
  for(int i=0; i<300; i++){
    rmn->bank_needed[i] = 1;
  }

  rmn->command_buf_needed[0] = 1;
  rmn->command_buf_needed[1] = 1;
  rmn->command_buf_needed[2] = 1;
  rmn->command_buf_needed[3] = 1;
  rmn->addr_buf_needed[0] = 1;
  rmn->addr_buf_needed[1] = 1;
  rmn->addr_buf_needed[2] = 1;
  rmn->addr_buf_needed[3] = 1;
  rmn->command_buf_needed[100] = 1;
  rmn->command_buf_needed[101] = 1;
  rmn->command_buf_needed[102] = 1;
  rmn->command_buf_needed[103] = 1;
  rmn->addr_buf_needed[100] = 1;
  rmn->addr_buf_needed[101] = 1;
  rmn->addr_buf_needed[102] = 1;
  rmn->addr_buf_needed[103] = 1;
  rmn->command_buf_needed[200] = 1;
  rmn->command_buf_needed[201] = 1;
  rmn->command_buf_needed[202] = 1;
  rmn->command_buf_needed[203] = 1;
  rmn->addr_buf_needed[200] = 1;
  rmn->addr_buf_needed[201] = 1;
  rmn->addr_buf_needed[202] = 1;
  rmn->addr_buf_needed[203] = 1;

}
//load register into request object                                                                                
Request* load_request(Request* request, MSHR* reg_ptr, int is_inst){
  if (reg_ptr != NULL){
    printf("MEM_CTRL: Loading with addr: %x\n", reg_ptr->pc_mem_addr);
    request->reg_ptr = reg_ptr;
    request->bank = ((reg_ptr->pc_mem_addr) >> 5) & 0x07;
    request->row = ((reg_ptr->pc_mem_addr) >> 16);
    request->time = pipe.time;
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
  printf("MEMCTRL: IN QUEUE_REQUEST with requests=%d, capacity=%d\n", q->requests, q->capacity);
  MSHR* temp_ptr = request->reg_ptr;
  int temp_bank = request->bank;
  int temp_row = request->row;
  int temp_source = request->source;
  uint32_t temp_time = request->time;
  //if our queue has no more room, make more
  if (q->requests == q->capacity){
    printf("MEMCTRL: Request Queue full, making more room\n");
    q->queue = realloc(q->queue, (q->capacity+1)*sizeof(Request*));
    for (i=0; i<q->capacity+1; i++)
      q->queue[i] = realloc(q->queue[i], sizeof(Request));
    q->queue[q->capacity]->reg_ptr = temp_ptr;
    q->queue[q->capacity]->bank = temp_bank;
    q->queue[q->capacity]->row = temp_row;
    q->queue[q->capacity]->source = temp_source;
    q->queue[q->capacity]->time = temp_time;
    q->capacity++;
    q->requests++;
    i -= 1;
  }
  else{
    printf("MEMCTRL: Extra room in the queue\n");
    for(i=0; i<q->capacity; i++){
      if (q->queue[i] == NULL){
	q->queue[i] = malloc(sizeof(Request));
	q->queue[i]->reg_ptr = temp_ptr;
	q->queue[i]->bank = temp_bank;
	q->queue[i]->row = temp_row;
	q->queue[i]->source = temp_source;
	q->queue[i]->time = temp_time;
	printf("q of 0: bank: %d\n", q->queue[0]->bank);
	break;
      }
    }
    q->requests++;
  }
  request_index = i;
  printf("MEMCTRL: Done queueing with request_index=%d, requests=%d, capacity=%d\n", request_index, q->requests, q->capacity);
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
  if (processQ->requests == processQ->capacity){
     processQ->queue = realloc(processQ->queue, (processQ->capacity+1)*sizeof(Request*));
     for (int i=0; i<processQ->capacity+1; i++)
       processQ->queue[i] = realloc(processQ->queue[i], sizeof(Request));

     processQ->queue[processQ->capacity]->reg_ptr = temp_ptr;
     processQ->queue[processQ->capacity]->bank = temp_bank;
     processQ->queue[processQ->capacity]->row = temp_row;
     processQ->queue[processQ->capacity]->source = temp_source;
     processQ->queue[processQ->capacity]->time = temp_time;
     processQ->queue[processQ->capacity]->process_count = temp_process_count;
     processQ->capacity++;
     processQ->requests++;
  }
  else{
    for(int i=0; i<processQ->capacity; i++){
      if (processQ->queue[i] == NULL){
	processQ->queue[i] = malloc(sizeof(Request));
        processQ->queue[i]->reg_ptr = temp_ptr;
	processQ->queue[i]->bank = temp_bank;
	processQ->queue[i]->row = temp_row;
	processQ->queue[i]->source = temp_source;
	processQ->queue[i]->time = temp_time;
	processQ->queue[i]->process_count = temp_process_count;
        break;
      }
    }
    processQ->requests++;
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
  printf("MEMCTRL: Finding Schedulables with capacity=%d, requests=%d\n", q->capacity, q->requests);
  for (int i=0; i<q->capacity; i++){
    if (q->queue[i] != NULL && is_schedulable(q->queue[i]) > 0){
      printf("MEMCTRL: q->queue[i]: %p\n", q->queue[i]);
      schedulables++;
      ptr = realloc(ptr, schedulables*sizeof(Request));
      ptr[schedulables-1] = *(q->queue[i]);
    }
  }
  return schedulables;
}

//finds row hits, returns number of row hits found
int find_row_hits(Request* ptr, int schedulables){
  int row_hits = 0;
  Request* hit_ptr;

  for (int i=0; i<schedulables; i++){
    if (ptr[i].row == (dram->banks[ptr[i].bank]).row_open){
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

  printf("MEMCTRL: is_schedulable, request->bank=%d, dram->banks[request->bank].row_open=%d\n", request->bank, dram->banks[request->bank].row_open);
  //if row buffer is closed
  if (dram->banks[request->bank].row_open == -1){
    printf("MEMCTRL: In is_schedulable, row closed\n");
    for (int i=0; i<350; i++){
      if (dram->data_buf_busy[i] & crn->data_buf_needed[i]){
	printf("MEMCTRL: Conflict with busy bank: Bank=%d, i=%d, busy=%d, needed=%d\n", request->bank, i, dram->data_buf_busy[i], crn->data_buf_needed[i]);
	return 0;
      }
      if (dram->command_buf_busy[i] & crn->command_buf_needed[i]) {
	printf("MEMCTRL: Conflict with busy bank: Bank=%d, i=%d, busy=%d, needed=%d\n", request->bank, i, dram->command_buf_busy[i], crn->command_buf_needed[i]);
	return 0;
      }
      if (dram->addr_buf_busy[i] & crn->addr_buf_needed[i]) {
       	printf("MEMCTRL: Conflict with busy addr buf: Bank=%d, i=%d, busy=%d, needed=%d\n", request->bank, i, dram->addr_buf_busy[i], crn->addr_buf_needed[i]);
	return 0;
      }
      if (dram->banks[request->bank].busy[i] & crn->bank_needed[i]){
	printf("MEMCTRL: Conflict with busy bank: Bank=%d, i=%d, busy=%d, needed=%d\n", request->bank, i, dram->banks[request->bank].busy[i], crn->bank_needed[i]);
	return 0;
      }
    }
    return 1;
  }    

  //its a row hit                                                                                                                            
  else if (dram->banks[request->bank].row_open == request->row){
    printf("MEMCTRL: In is_schedulable, row hit\n");
    for (int i=0; i<350; i++){
      if (dram->data_buf_busy[i] & rhn->data_buf_needed[i]) return 0;
      if (dram->command_buf_busy[i] & rhn->command_buf_needed[i]) return 0;
      if (dram->addr_buf_busy[i] & rhn->addr_buf_needed[i]) return 0;
      if (dram->banks[request->bank].busy[i] & rhn->bank_needed[i]) return 0;
    }
    return 1;
  }

  //its a row miss
  else{
    printf("MEMCTRL: In is_schedulable, row miss\n");
    for (int i=0; i<350; i++){
      if (dram->data_buf_busy[i] & rmn->data_buf_needed[i]) return 0;
      if (dram->command_buf_busy[i] & rmn->command_buf_needed[i]) return 0;
      if (dram->addr_buf_busy[i] & rmn->addr_buf_needed[i]) return 0;
      if (dram->banks[request->bank].busy[i] & rmn->bank_needed[i]) return 0;
    }
    return 1;
  }
  
}


//set_channel_values
void set_channel_vals(Request* request){

  //if the row buffer is closed
  printf("0=%d,1=%d,2=%d,3=%d,4=%d,5=%d,6=%d,7=%d\n", dram->banks[0].row_open,dram->banks[1].row_open,dram->banks[2].row_open,dram->banks[3].row_open,dram->banks[4].row_open,dram->banks[5].row_open,dram->banks[6].row_open,dram->banks[7].row_open);
  if (dram->banks[request->bank].row_open == -1){
    for (int i=0; i<350; i++){
      dram->data_buf_busy[i] = dram->data_buf_busy[i] | crn->data_buf_needed[i];
      dram->command_buf_busy[i] = dram->command_buf_busy[i] | crn->command_buf_needed[i];
      dram->addr_buf_busy[i] = dram->addr_buf_busy[i] | crn->addr_buf_needed[i];
      dram->banks[request->bank].busy[i] = dram->banks[request->bank].busy[i] | crn->bank_needed[i];
    }
    request->process_count = 250;
  }

  //its a row hit
  else if (dram->banks[request->bank].row_open == request->row){
    for (int i=0; i<350; i++){
      dram->data_buf_busy[i] = dram->data_buf_busy[i] | rhn->data_buf_needed[i];
      dram->command_buf_busy[i] = dram->command_buf_busy[i] | rhn->command_buf_needed[i];
      dram->addr_buf_busy[i] = dram->addr_buf_busy[i] | rhn->addr_buf_needed[i];
      dram->banks[request->bank].busy[i] = dram->banks[request->bank].busy[i] | rhn->bank_needed[i];
    }
    request->process_count = 150;
  }

  //its a row miss
  else {
    for (int i=0; i<350; i++){
      dram->data_buf_busy[i] = dram->data_buf_busy[i] | rmn->data_buf_needed[i];
      dram->command_buf_busy[i] = dram->command_buf_busy[i] | rmn->command_buf_needed[i];
      dram->addr_buf_busy[i] = dram->addr_buf_busy[i] | rmn->addr_buf_needed[i];
      dram->banks[request->bank].busy[i] = dram->banks[request->bank].busy[i] | rmn->bank_needed[i];
    }
    request->process_count = 350;
  }
  
  process_queue_request(request);
  dram->banks[request->bank].row_open = request->row;
  printf("MEMCTRL: Just set values, Bank=%d, row open=%d\n", request->bank, dram->banks[request->bank].row_open);
  remove_from_queue(q, request_index);
}

//shift the channel values every cycle
void shift_channel_vals(){
  for (int i=1; i<350; i++){
    dram->data_buf_busy[i-1] = dram->data_buf_busy[i];
    dram->command_buf_busy[i-1] = dram->command_buf_busy[i];
    dram->addr_buf_busy[i-1] = dram->addr_buf_busy[i];
    for (int j=0; j<8; j++){
      dram->banks[j].busy[i-1] = dram->banks[j].busy[i];
    }
  }


  dram->data_buf_busy[349] = 0;
  dram->command_buf_busy[349] = 0;
  dram->addr_buf_busy[349] = 0;
  for (int j=0; j<8; j++){
    dram->banks[j].busy[349] = 0;
  }

  //decrement all process counts for requests being processed
  //if it is zero then we know dram is done processing so we set the done bit for the corresponding MSHR
  //and remove it from the process list
  for (int i=0; i<processQ->capacity; i++){
    if (processQ->queue[i] != NULL){
      printf("MEMCTRL: Processing Request: Process_count=%d\n", processQ->queue[i]->process_count);
      (processQ->queue[i])->process_count--;
      if ((processQ->queue[i])->process_count == 0){
	printf("MEMCTRL: Processing Done, Sending Fill Notification to L2");
	//	dram->banks[(processQ->queue[i])->bank].row_open = -1;
	((processQ->queue[i])->reg_ptr)->done = 1;
	remove_from_queue(processQ, i);
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
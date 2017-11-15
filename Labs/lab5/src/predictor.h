#include <stdint.h>


#ifndef _PREDICT_H_
#define _PREDICT_H_

typedef struct entry_t{
  uint32_t tag;
  int v;
  int is_conditional;
  uint32_t target;
} entry_t;

uint32_t predict_branch(uint32_t pc, int *predicted_taken, int *BTBmiss);
void predict_init();
void update_predictor(int was_taken, struct entry_t newBTB);

#endif

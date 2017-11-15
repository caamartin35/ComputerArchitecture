#include <stdint.h>
#include "objects.h"

#ifndef _PREDICT_H_
#define _PREDICT_H_

uint32_t predict_branch(uint32_t pc, int *predicted_taken, int *BTBmiss);
void init_predictor();
void update_predictor(int was_taken, struct BTBentry newBTB);

typedef struct Predictor {
	unsigned char GHR;
	unsigned char PHT[256];
	struct BTBentry BTB[1024];
} Predictor;
#endif

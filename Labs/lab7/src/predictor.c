#include "predictor.h"
#include "pipe.h"
#include "processor.h"
#include <stdio.h>

uint32_t predict_branch(uint32_t pc, int *predicted_taken, int *BTBmiss){
  uint32_t PHTindex;
  uint32_t BTBindex;

  PHTindex = ((pc >> 2) & 0xff)^(core->predictor.GHR);
  BTBindex = (pc >> 2) & 0x03ff;

  //predict from BTB
  if (core->predictor.BTB[BTBindex].tag == pc && core->predictor.BTB[BTBindex].v == 1){
    if (!core->predictor.BTB[BTBindex].is_conditional || core->predictor.PHT[PHTindex] > 1){
      *BTBmiss = 0;
      *predicted_taken = 1;
      return core->predictor.BTB[BTBindex].target;
    }
    else {
      *BTBmiss = 0;
      *predicted_taken = 0;
      return pc + 4;
    }
  }
  else {
    *BTBmiss = 1;
    *predicted_taken = 0;
    return pc + 4;
  }
}

void init_predictor(){
  int i;

  //clear GHR
  core->predictor.GHR = 0x00;
  
  //clear PHT
  for (i=0; i<256; i++){
    core->predictor.PHT[i] = 0x00;
  }

  //clear BTB
  for (i=0; i<1024; i++){
    core->predictor.BTB[i].tag = 0;
    core->predictor.BTB[i].v = 0;
    core->predictor.BTB[i].is_conditional = 0;
    core->predictor.BTB[i].target = 0;
  }
}

void update_predictor(int was_taken, struct BTBentry newBTB){
  uint32_t BTBindex;
  uint32_t PHTindex;
  int i;
  struct entry_t *LRU;

  PHTindex = ((newBTB.tag >> 2) & 0xff)^(core->predictor.GHR);
  BTBindex = (newBTB.tag >> 2) & 0x03ff;

  printf("GHR: GHR=%x\n", core->predictor.GHR);
  printf("PHT: PHT[PHTindex]=%d, was_taken=%d\n", core->predictor.PHT[PHTindex], was_taken); 
  printf("BTB: BTBindex=%d, BTB.tag=%x, BTB.v=%d, BTB.is_cond=%d, BTB.target=%x\n", BTBindex, core->predictor.BTB[BTBindex].tag, core->predictor.BTB[BTBindex].v, core->predictor.BTB[BTBindex].is_conditional, core->predictor.BTB[BTBindex].target);

  //PHT and GHR update
  if (newBTB.is_conditional){
    if (was_taken) {
      if (core->predictor.PHT[PHTindex] != 3) core->predictor.PHT[PHTindex]++;
      else core->predictor.PHT[PHTindex] = 3;
      (core->predictor.GHR) = ((core->predictor.GHR) << 1) | 1;
      printf("POO on GHR: %x\n", core->predictor.GHR);
    }
    else{ 
      if (core->predictor.PHT[PHTindex] != 0) core->predictor.PHT[PHTindex]--;
      else core->predictor.PHT[PHTindex] = 0;
      core->predictor.GHR = (core->predictor.GHR << 1);
      printf("PEE on GHR: %x\n", core->predictor.GHR);
    }
  }
  printf("GHR updated: GHR=%x\n", core->predictor.GHR);

  //BTB update
  core->predictor.BTB[BTBindex].tag = newBTB.tag;
  core->predictor.BTB[BTBindex].v = newBTB.v;
  core->predictor.BTB[BTBindex].is_conditional = newBTB.is_conditional;
  core->predictor.BTB[BTBindex].target = newBTB.target;
  
  printf("BTB updated: BTBindex=%d, BTB.tag=%x, BTB.v=%d, BTB.is_cond=%d, BTB.target=%x\n", BTBindex, core->predictor.BTB[BTBindex].tag, core->predictor.BTB[BTBindex].v, core->predictor.BTB[BTBindex].is_conditional,core->predictor.BTB[BTBindex].target);

}


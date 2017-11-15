#include "predictor.h"
#include "pipe.h"
#include <stdio.h>

unsigned char GHR;
unsigned char PHT[256];
struct entry_t BTB[1024];

uint32_t predict_branch(uint32_t pc, int *predicted_taken, int *BTBmiss){
  uint32_t PHTindex;
  uint32_t BTBindex;

  PHTindex = ((pc >> 2) & 0xff)^GHR;
  BTBindex = (pc >> 2) & 0x03ff;

  //predict from BTB
  if (BTB[BTBindex].tag == pc && BTB[BTBindex].v == 1){
    if (!BTB[BTBindex].is_conditional || PHT[PHTindex] > 1){
      *BTBmiss = 0;
      *predicted_taken = 1;
      return BTB[BTBindex].target;
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

void predict_init(){
  int i;

  //clear GHR
  GHR = 0x00;
  
  //clear PHT
  for (i=0; i<256; i++){
    PHT[i] = 0x00;
  }

  //clear BTB
  for (i=0; i<1024; i++){
    BTB[i].tag = 0;
    BTB[i].v = 0;
    BTB[i].is_conditional = 0;
    BTB[i].target = 0;
  }
}

void update_predictor(int was_taken, struct entry_t newBTB){
  uint32_t BTBindex;
  uint32_t PHTindex;
  int i;
  struct entry_t *LRU;

  PHTindex = ((newBTB.tag >> 2) & 0xff)^GHR;
  BTBindex = (newBTB.tag >> 2) & 0x03ff;

  printf("GHR: GHR=%x\n", GHR);
  printf("PHT: PHT[PHTindex]=%d, was_taken=%d\n", PHT[PHTindex], was_taken); 
  printf("BTB: BTBindex=%d, BTB.tag=%x, BTB.v=%d, BTB.is_cond=%d, BTB.target=%x\n", BTBindex, BTB[BTBindex].tag, BTB[BTBindex].v, BTB[BTBindex].is_conditional, BTB[BTBindex].target);

  //PHT and GHR update
  if (newBTB.is_conditional){
    if (was_taken) {
      if (PHT[PHTindex] != 3) PHT[PHTindex]++;
      else PHT[PHTindex] = 3;
      GHR = (GHR << 1) | 1;
      printf("POO on GHR: %x\n", GHR);
    }
    else{ 
      if (PHT[PHTindex] != 0) PHT[PHTindex]--;
      else PHT[PHTindex] = 0;
      GHR = (GHR << 1);
      printf("PEE on GHR: %x\n", GHR);
    }
  }
  printf("GHR updated: GHR=%x\n", GHR);

  //BTB update
  BTB[BTBindex].tag = newBTB.tag;
  BTB[BTBindex].v = newBTB.v;
  BTB[BTBindex].is_conditional = newBTB.is_conditional;
  BTB[BTBindex].target = newBTB.target;
  
  printf("BTB updated: BTBindex=%d, BTB.tag=%x, BTB.v=%d, BTB.is_cond=%d, BTB.target=%x\n", BTBindex, BTB[BTBindex].tag, BTB[BTBindex].v, BTB[BTBindex].is_conditional,BTB[BTBindex].target);

}


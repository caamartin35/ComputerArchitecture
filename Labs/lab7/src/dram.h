#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include "objects.h"

#ifndef _DRAM_H_
#define _DRAM_H_
typedef struct DRAM{
  int data_buf_busy[350];
  int command_buf_busy[350];
  int addr_buf_busy[350];
  Bank banks[8];
} DRAM;

#endif

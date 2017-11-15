#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>

//row open is -1 if all rows are closed in bank
typedef struct Bank{
  int row_open;
  int busy[350];
} Bank;

typedef struct DRAM{
  int data_buf_busy[350];
  int command_buf_busy[350];
  int addr_buf_busy[350];
  Bank banks[8];
} DRAM;



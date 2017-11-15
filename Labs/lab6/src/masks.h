#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <assert.h>
#include <stdint.h>

typedef struct closed_row_needed{
  int data_buf_needed[350];
  int command_buf_needed[350];
  int addr_buf_needed[350];
  int bank_needed[350];
} closed_row_needed;

typedef struct row_hit_needed{
  int data_buf_needed[350];
  int command_buf_needed[350];
  int addr_buf_needed[350];
  int bank_needed[350];
} row_hit_needed;

typedef struct row_miss_needed{
  int data_buf_needed[350];
  int command_buf_needed[350];
  int addr_buf_needed[350];
  int bank_needed[350];
} row_miss_needed;


#ifndef _DEFINES_H_
#define _DEFINES_H_

//MESI STATES
#define INVALID 0
#define SHARED 1
#define MODIFIED 2
#define EXCLUSIVE 3

//L2 MISS STATES
#define L2_INSERTION 0
#define L1_INSERTION 1
#define FREE_MSHR 2;
#define COMPLETE_REQUEST 3;

//L1 MISS STATES
#define WRITE_EXCLUSION 0
#define CHECK_MSHRS 1
#define MSHR_AVAIL 2
#define PROBE_OTHER_L1S 3
#define FIO_L1_R 4
#define FIO_L1_W 5
#define L1_WRITEBACK 6
#define PROBE_L2 7
#define GO_TO_MEM 8

//CACHE BLOCK REQUESTER and SOURCE
#define CORE0 0
#define CORE1 1
#define CORE2 2
#define CORE3 3


#endif

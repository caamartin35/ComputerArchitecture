////
//// Internal signal constants
////

// ALU
`define ALU_ADD      4'b0000
`define ALU_SUB      4'b0001
`define ALU_AND      4'b0010
`define ALU_NOR      4'b0011
`define ALU_OR       4'b0100
`define ALU_XOR      4'b0101
`define ALU_SET      4'b0110
`define ALU_SETU     4'b0111
`define ALU_SLL      4'b1000
`define ALU_SRL      4'b1001
`define ALU_SRA      4'b1010
`define ALU_BRANCH   4'b1011
`define ALU_LU       4'b1100
`define ALU_LS       4'b1101

//ALUSRC2MUX
`define SRC2_RT     3'b00
`define SRC2_SE_IMM 3'b01
`define SRC2_E_IMM  3'b10
`define SRC2_0      3'b11

//ALUSRC1MUX
`define SRC1_RS     2'b00
`define SRC1_PCNEXT 2'b01
`define SRC1_SA     2'b10

//PCMUX
`define PC_INC       2'b00
`define PC_ALU       2'b01
`define PC_RS        2'b10
`define PC_TARGET    2'b11

//RDMUX
`define RD_ALU       2'b00
`define RD_MEM       2'b01
`define RD_MUL    2'b10

//REGWRITE
`define REG_READ     1'b0
`define REG_WRITE    1'b1

//MEMEXTEND
`define MEMEXT_SE    1'b0
`define MEMEXT_E     1'b1

//WORDSIZE
`define SIZE_BYTE    2'b00
`define SIZE_HALF    2'b01
`define SIZE_WORD    2'b10